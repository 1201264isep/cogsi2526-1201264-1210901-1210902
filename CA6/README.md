## Análise

### Jenkins vs. GitHub Actions

*   **Jenkins**: É um servidor de automação *open-source* criado para suportar a criação, teste e *deployment* de software. Funciona como uma solução *self-hosted*, onde o utilizador é responsável por gerir o servidor, o sistema operativo e as dependências. É conhecido pela sua extrema flexibilidade e por um vasto sistema de plugins, permitindo a integração com praticamente qualquer ferramenta através de scripts  (geralmente em Groovy).

*   **GitHub Actions**: É uma plataforma de CI/CD (Integração Contínua e Entrega Contínua) baseada na cloud e  integrada nos repositórios GitHub. Ao contrário do Jenkins, opera num modelo SaaS (*Software as a Service*), eliminando a necessidade de gestão de servidores para a maioria dos casos de uso. Utiliza ficheiros YAML para definir *workflows* automatizados e tira partido de um ecossistema de "Actions" pré-construídas pela comunidade e verificadas pelo GitHub, facilitando a configuração rápida de *pipelines*.

| **Aspeto** | **Jenkins**                                                                                                                                                                          | **GitHub Actions**                                                                                                                                         |
| :--- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Infraestrutura e Manutenção** | Modelo *Self-Hosted*. Requer instalação, configuração manual do servidor, atualizações de segurança e gestão de capacidade dos agentes de *build*.                                   | Modelo *Cloud-native*. A infraestrutura é gerida pelo GitHub geralmente mas suporta *self-hosted runners* se necessário.                                   |
| **Integração com Controlo de Versão** | Externa. Liga-se ao GitHub (ou outros git remotos) via *webhooks* e plugins.                                                                                                         | Nativa. Os *checks* de CI/CD aparecem diretamente na interface dos *Pull Requests* e a configuração reside no próprio repositório (`.github/workflows`).   |
| **Configuração de Pipelines** | Baseada em *Jenkinfiles* (declarativos ou *scripted*), frequentemente utilizando a linguagem Groovy.      | Baseada em ficheiros YAML. Sintaxe mais simples e legível focada na composição de tarefas.                                                                 |
| **Escalabilidade** | Manual ou requer orquestração complexa. É necessário configurar nós adicionais (*slaves*) e gerir o balanceamento de carga.                                                          | Automática no modelo *cloud*. O GitHub provisiona ambientes de execução (*runners*) conforme a necessidade dos *jobs* paralelos.                           |
| **Segurança** | Da responsabilidade do administrador. É necessário garantir o *hardening* do servidor Jenkins e gerir permissões de utilizadores granularmente.                                      | Gerida pela plataforma. Oferece gestão de segredos encriptados e conformidade de segurança gerida pelo GitHub.                                             |

### Principais diferenças técnicas

#### 1. Arquitetura de Execução (Stateful vs. Stateless)
A diferença fundamental reside na persistência do ambiente.
*   **No Jenkins:** O servidor é persistente (*stateful*). O ambiente de *build* pode acumular "lixo" (ficheiros temporários, configurações globais alteradas) se não for limpo após cada execução.
*   **No GitHub Actions:** Cada *job* é executado num ambiente virtual (VM ou Container) *stateless*. Isto garante que o ambiente de teste é sempre limpo e idêntico.
#### 2. Ecossistema de Extensões
*   **Plugins do Jenkins:** São instalados ao nível do servidor. Uma atualização de um plugin para um projeto pode quebrar a *pipeline* de outro projeto que partilhe o mesmo servidor.
*   **Marketplace do GitHub:** As *Actions* são referenciadas por versão no código do *workflow* (ex: `actions/checkout@v3`). Isto permite que diferentes projetos usem diferentes versões da mesma ferramenta sem conflitos.

#### 3. Barreira de Entrada
Para equipas que já utilizam GitHub, a fricção inicial do Actions é praticamente nula.
*   **Contexto:** O GitHub Actions tem acesso imediato ao contexto do repositório (código, *issues*, *tags*) sem configuração adicional. O Jenkins necessita da configuração de credenciais, chaves SSH e *webhooks* bidirecionais para atingir o mesmo nível de automação.

## IMPLEMENTAÇÃO

#### Configuração dos Self-Hosted Runners

Para esta implementação, optámos por utilizar self-hosted runners para executar os nossos workflows do GitHub Actions, em vez dos runners do GitHub.

Esta abordagem foi necessária para garantir que a pipeline  tivesse acesso direto à nossa infraestrutura (máquinas virtuais criadas no VirtualBox). Configurámos o runner na nossa máquina  seguindo os passos fornecidos pelo GitHub em Settings > Actions > Runners > New self-hosted runner.

#### Part 1: CI/CD Pipeline for Deploying Building REST services with Spring application and deploys it to a local virtual machine using GitHub Actions
- Criar um ficheiro chamado .github/workflows/ci-dc.yml na base do repositório com o seguinte conteúdo:
```yaml
name: CI/CD Pipeline

permissions:
  contents: write

on:
  push:
    branches: [ main, development ]
  workflow_dispatch:

env:
  ARTIFACT_NAME: rest-service-0.0.1-SNAPSHOT.jar
  APP_PATH: CA2-part2/tut-gradle

jobs:
  build-and-test:
    runs-on: self-hosted

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Make gradlew executable
        run: chmod +x ./gradlew
        working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

      - name: Assemble
        run: |
          echo "Assembling the application..."
          ./gradlew clean assemble
        working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

      - name: Test
        run: |
          echo "Running unit tests..."
          ./gradlew test
        working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

      - name: Publish Test Results
        if: always() && (github.event_name == 'push' || github.event_name == 'workflow_dispatch')
        run: |
          REPORT_PATH="${{ github.workspace }}/CA2-part2/tut-gradle/build/test-results/test/*.xml"
          shopt -s nullglob
          files=($REPORT_PATH)
          if [ ${#files[@]} -gt 0 ]; then
            echo "Publishing test reports..."
            echo "path=$REPORT_PATH" >> $GITHUB_OUTPUT
          else
            echo "No test reports found, skipping."
          fi
        shell: bash

      - name: Run Test Reporter
        uses: dorny/test-reporter@v1
        if: steps.publish-reports.outputs.path != ''
        with:
          name: Test Results
          path: ${{ steps.publish-reports.outputs.path }}
          reporter: java-junit

      - name: Tag stable build
        if: success()
        run: |
          echo "Tagging stable build..."
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git tag stable-v${{ github.run_number }}
          git push origin stable-v${{ github.run_number }}

      - name: Archive Artifact
        uses: actions/upload-artifact@v4
        if: success()
        with:
          name: application-jar
          path: ${{ github.workspace }}/CA2-part2/tut-gradle/build/libs/*.jar

  deploy-approval:
    needs: build-and-test
    runs-on: self-hosted
    if: success()
    environment:
      name: production
      url: http://192.168.56.12:8080

  deploy:
    needs: deploy-approval
    runs-on: self-hosted
    if: success()

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Artifact
        uses: actions/download-artifact@v4
        with:
          name: application-jar
          path: ./artifacts

      - name: Set up Python for Ansible
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'

      - name: Install Ansible
        run: |
          pip install ansible

      - name: Check VM is Ready
        run: |
          echo "Checking if green VM is accessible..."
          until ssh -o StrictHostKeyChecking=no vagrant@192.168.56.12 'echo ready' 2>/dev/null; do
            echo "Waiting for VM..."
            sleep 5
          done
          echo "VM is ready!"


      - name: Deploy to Green VM
        env:
          ARTIFACT_PATH: ${{ github.workspace }}/artifacts/${{ env.ARTIFACT_NAME }}
        run: |
          echo "Deploying to Green VM..."
          ansible-playbook -i CA6/part1/host.ini CA6/part1/green.yml \
            --extra-vars "artifact_path=${ARTIFACT_PATH}"

      - name: Health Check
        if: success()
        run: |
          echo "Running health check on Green VM..."
          for i in {1..5}; do
            if curl -f http://192.168.56.12:8080/employees; then
              echo "Health check passed!"
              exit 0
            fi
            echo "Attempt $i failed, retrying..."
            sleep 5
          done
          echo "Health check failed!"
          exit 1

```

Este ficheiro replica as fases e funcionalidades do nosso Jenkinsfile.
1. Build and Test
- O job build-and-test:
    - Faz o checkout do código..
    - Configura o JDK 17.
    - Constrói a aplicação e executa os testes.
    - Carrega os resultados dos testes e os artefactos de construção (ficheiros JAR) como artefactos para serem usados.
2. Deployment to Green VM
- O job deploy-to-green:
    - Depende do sucesso de build-and-test.
    - É acionado apenas quando iniciado manualmente tendo que ser aprovado no environment das actions.
    - Instala o Ansible e executa o playbook green.yml para dar deploy à aplicação na VM green.



#### Part 2: CI/CD Pipeline for Deploying a Spring Application with Docker using GitHub Actions
- Criar um ficheiro deploy-spring.yml no diretório .github/workflows com a seguinte configuração

```yaml
   name: Part 2 - Docker Deployment Pipeline

   permissions:
     contents: write

   on:
     push:
       branches: [ main, development ]
     workflow_dispatch:

   env:
     DOCKER_IMAGE: 1210902/spring-rest-service
     APP_PATH: CA2-part2/tut-gradle

   jobs:
     build-and-test:
       runs-on: self-hosted

       steps:
         - name: Checkout
           uses: actions/checkout@v4
           with:
             fetch-depth: 0

         - name: Set up JDK 17
           uses: actions/setup-java@v4
           with:
             java-version: '17'
             distribution: 'temurin'

         - name: Make gradlew executable
           run: chmod +x ./gradlew
           working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

         - name: Assemble
           run: |
             echo "Assembling the application..."
             ./gradlew clean assemble
           working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

         - name: Test
           run: |
             echo "Running unit tests..."
             ./gradlew test
           working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

         - name: Publish Test Results
           if: always()
           uses: dorny/test-reporter@v1
           with:
             name: Test Results
             path: ${{ github.workspace }}/CA2-part2/tut-gradle/build/test-results/test/*.xml
             reporter: java-junit

         - name: Set Docker Tag
           id: docker_tag
           run: |
             if [ "${{ github.ref }}" == "refs/heads/main" ]; then
               echo "tag=latest" >> $GITHUB_OUTPUT
             else
               echo "tag=${{ github.ref_name }}-${{ github.run_number }}" >> $GITHUB_OUTPUT
             fi

         - name: Build Docker Image
           run: |
             echo "Building Docker image: ${{ env.DOCKER_IMAGE }}:${{ steps.docker_tag.outputs.tag }}"
             docker build -t ${{ env.DOCKER_IMAGE }}:${{ steps.docker_tag.outputs.tag }} .
           working-directory: ${{ github.workspace }}/CA2-part2/tut-gradle

         - name: Login to Docker Hub
           uses: docker/login-action@v3
           with:
             username: ${{ secrets.DOCKER_USERNAME }}
             password: ${{ secrets.DOCKER_PASSWORD }}

         - name: Push Docker Image
           run: |
             echo "Pushing Docker image to Docker Hub..."
             docker push ${{ env.DOCKER_IMAGE }}:${{ steps.docker_tag.outputs.tag }}

             # Also push as 'latest' if on main branch
             if [ "${{ github.ref }}" == "refs/heads/main" ]; then
               docker tag ${{ env.DOCKER_IMAGE }}:${{ steps.docker_tag.outputs.tag }} ${{ env.DOCKER_IMAGE }}:latest
               docker push ${{ env.DOCKER_IMAGE }}:latest
             fi

         - name: Tag stable build
           if: success() && github.event_name == 'push'
           run: |
             echo "Tagging stable build..."
             git config user.name "github-actions"
             git config user.email "github-actions@github.com"
             git tag stable-part2-v${{ github.run_number }}
             git push origin stable-part2-v${{ github.run_number }}

     deploy-approval:
       needs: build-and-test
       runs-on: self-hosted
       if: success() && github.ref == 'refs/heads/main'
       environment:
         name: production-docker
         url: http://192.168.56.20:8080

       steps:
         - name: Manual Approval
           run: |
             echo "Manual approval granted. Proceeding to deploy..."

     deploy:
       needs: deploy-approval
       runs-on: self-hosted
       if: success()

       steps:
         - name: Checkout
           uses: actions/checkout@v4

         - name: Set up Python for Ansible
           uses: actions/setup-python@v5
           with:
             python-version: '3.x'

         - name: Install Ansible
           run: |
             pip install ansible

         - name: Check Production VM is Ready
           run: |
             echo "Checking if Production VM is accessible..."
             until ssh -o StrictHostKeyChecking=no vagrant@192.168.56.20 'echo ready' 2>/dev/null; do
               echo "Waiting for VM..."
               sleep 5
             done
             echo "VM is ready!"

         - name: Deploy to Production VM
           env:
             DOCKER_IMAGE: ${{ env.DOCKER_IMAGE }}:latest
             DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
             DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
           run: |
             echo "Deploying Docker container to Production VM..."
             ansible-playbook -i CA6/part2/host.ini CA6/part2/deploy.yml \
               --extra-vars "docker_image=${DOCKER_IMAGE} docker_username=${DOCKER_USERNAME} docker_password=${DOCKER_PASSWORD}"

         - name: Health Check
           if: success()
           run: |
             echo "Running health check on Production VM..."
             for i in {1..10}; do
               if curl -f http://192.168.56.20:8080/employees; then
                 echo "✓ Health check passed!"
                 exit 0
               fi
               echo "Attempt $i failed, retrying..."
               sleep 5
             done
             echo "✗ Health check failed!"
             exit 1
```
Esta configuração define um workflow do GitHub Actions que automatiza a pipeline de CI/CD para dar deploy a uma aplicação Spring com Docker.
O workflow é acionado em eventos de push para a branch main e executa os seguintes passos.

1. Instalar as dependências necessárias.
2. Fazer o checkout do código do repositório.
3. Montar o projeto executando o comando ./gradlew clean assemble.
4. Executar testes unitários e de integração.
5. Construir e etiquetar a imagem Docker.
6. Enviar a imagem Docker para o Docker Hub.
7. Implantar a aplicação usando Ansible.
8. Realizar uma verificação de integridade (health check) na aplicação implantada.

- Após criar o ficheiro do workflow, fazemos o push para o repositório para acionar a pipeline.
- Podemos aceder ao separador GitHub Actions no repositório para ver as execuções do workflow e os logs.
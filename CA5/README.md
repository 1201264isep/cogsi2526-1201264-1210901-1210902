# CA5 - Containers

## Table of Contents
1. [Creating and Managing Docker Images](#creating-and-managing-docker-images)
   1. [Setting Up Docker](#setting-up-docker)
   2. [Packaging Applications into Docker Containers](#packaging-applications-into-docker-containers)
   3. [Creating Docker Images: Two Approaches](#creating-docker-images-two-approaches)
   4. [Understanding Docker Image Layers and Monitoring](#understanding-docker-image-layers-and-monitoring)
   5. [Publishing](#publishing)
   6. [Optimize the Dockerfiles](#optimize-the-dockerfiles)
2. [Containerized Environment with Docker Compose](#containerized-environment-with-docker-compose)
   1. [Overview of Docker Compose](#overview-of-docker-compose)
   2. [Setting Up Containers](#setting-up-containers)
   3. [Testing Container Networking and Health Checks](#testing-container-networking-and-health-checks)
   4. [Data Persistence with Docker Volumes](#data-persistence-with-docker-volumes)
   5. [Publishing](#publishing)
3. [Useful Docker and Docker Compose Commands](#useful-docker-and-docker-compose-commands)
4. [Docker Alternative](#docker-alternative)



## Creating and Managing Docker Images
Nesta secção, exploraremos o processo de criação e gestão de imagens Docker para aplicações. As imagens Docker são os blocos de construção dos contentores, proporcionando um ambiente leve, portátil e consistente para a execução de aplicações.

As etapas a seguir descrevem a implementação da solução:
### Setting Up Docker

1. Update aos packages:
```
sudo apt update
sudo apt upgrade -y
```
2. Instalar as dependências:
```
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
```
3. Adicionar a Docker GPG key:
```
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```
4. Instalar o Docker:
```
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
```
5. Verificar a instalação:
```
docker --version
```


### Packaging Applications into Docker Containers
Para dockerizar a aplicação de chat e a API Spring REST, precisamos criar imagens Docker para cada aplicação. As imagens Docker conterão as dependências, configurações e código de aplicação necessários para executar as aplicações em contentores.

#### Chat Application Dockerfile
Dentro da pasta CA2, onde está localizado o código do aplicação chat, crio um Dockerfile com o seguinte conteúdo:
```Dockerfile
# Use an official OpenJDK runtime as the base image
FROM openjdk:17-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the jar file (assuming you have built the app into a jar using Gradle)
COPY build/libs/basic_demo-0.1.0.jar /app/basic_demo-0.1.0.jar

# Set the command to run the chat server
CMD ["java", "-cp", "/app/basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]
```
Este ficheiro define as etapas para criar uma imagem Docker para a aplicação de chat:
- **FROM**: Especifica a imagem base a ser usada, neste caso, a imagem oficial openjdk:17-jdk-slim.
- **WORKDIR**: Define o diretório de trabalho dentro do contentor onde o código do aplicativo será copiado.
- **COPY**: Copia o arquivo JAR compilado do projeto para o diretório de trabalho do contentor. Certifique-se de compilar o arquivo JAR antes de criar a imagem Docker. Para isso, execute `./gradlew build` na pasta da aplicação chat.
- **CMD**: Define o comando para executar o servidor de chat quando o contentor é iniciado. O comando especifica o classpath e a classe principal para executar o ChatServerApp na porta 59001.


#### Spring REST API Dockerfile
Dentro da pasta CA2/CA2_part2, onde está localizado o código da API REST do Spring, crio um Dockerfile com o seguinte conteúdo:
```Dockerfile
# Use official openjdk base image for Spring Boot
FROM openjdk:17-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the built JAR file from your project
COPY build/libs/basic_demo.jar /app/basic_demo.jar

# Expose port 8080 for the Spring Boot app
EXPOSE 8080

# Run the Spring Boot app
ENTRYPOINT ["java", "-jar", "basic_demo.jar"]
```
Este ficheiro define as etapas para criar uma imagem Docker para a aplicação chat:
- **FROM**: Especifica a imagem base a ser usada, neste caso, a imagem oficial openjdk:17-jdk-slim.
- **WORKDIR**: Define o diretório de trabalho dentro do contentor onde o código da aplicação será copiado.
- **COPY**: Copia o arquivo JAR compilado do projeto para o diretório de trabalho do contentor. Certifico-me de compilar o arquivo JAR antes de criar a imagem Docker. Para isso, executo `./gradlew build` na pasta do aplicativo Spring.
- **EXPOSE**: expõe a porta 8080 para a aplicação Spring Boot escutar.
- **ENTRYPOINT**: define o comando para executar a aplicação Spring Boot quando o contentor é iniciado.

### Creating Docker Images: Two Approaches

#### Version 1: Building the Server Inside the Dockerfile

##### Chat Application
Para criar a imagem Docker da aplicação chat, crio outro ficheiro Dockerfile numa pasta à escolha com o seguinte conteúdo:
```Dockerfile
# Stage 1: Build the application inside the container
FROM openjdk:17-jdk-slim AS builder
# Set the working directory in the container
WORKDIR /app
# Install Git and Gradle (or any dependencies you need to build the app)
RUN apt-get update && \
    apt-get install -y git gradle
# Add an ARG instruction to pass the GitHub token
ARG GITHUB_TOKEN
# Clone the repository into the container using the token
RUN git clone https://${GITHUB_TOKEN}@github.com/britz27/cogsi2425_1201461_1240469_1240448_1211497.git /app
# Set the working directory inside the cloned repo
WORKDIR /app/CA2
# Grant execute permissions to the Gradle wrapper script
RUN chmod +x gradlew
# Build the application using Gradle
RUN ./gradlew build --no-daemon
# Verify that the jar file was created
RUN ls -R /app/CA2/build/libs
# Stage 2: Use an official OpenJDK runtime as the base image
FROM openjdk:17-jdk-slim
# Set the working directory in the container
WORKDIR /app
# Copy the jar file (assuming it was built successfully)
COPY --from=builder /app/CA2/build/libs/basic_demo-0.1.0.jar /app/basic_demo-0.1.0.jar
# Set the command to run the chat server
CMD ["java", "-cp", "basic_demo-0.1.0.jar", "basic_demo.ChatServerApp", "59001"]
```
Este Dockerfile reutiliza o Dockerfile anterior para a aplicação chat, mas adiciona um processo de compilação em várias etapas para clonar o código da aplicação a partir de um repositório GitHub privado usando um token GitHub. O processo de compilação é dividido em duas etapas:
- **Etapa 1 (compilador)**: Clona o repositório, compila a aplicação usando Gradle e verifica a criação do ficheiro JAR.
    - A instrução ARG é usada para passar o token do GitHub com segurança durante o processo de compilação.
- O comando git clone procura o repositório usando o token para autenticação.
- O comando de compilação Gradle compila o aplicativo e cria o ficheiro JAR.
- O comando ls lista o conteúdo do diretório build/libs para verificar o ficheiro JAR.
- **Etapa 2**: Utiliza o tempo de execução oficial do OpenJDK como imagem base e copia o ficheiro JAR compilado da fase de compilação para a imagem final. A instrução CMD especifica o comando para executar o servidor de chat.

##### Spring REST API
Para criar a imagem Docker da API REST do Spring, crie outro ficheiro Dockerfile numa pasta à sua escolha com o seguinte conteúdo:
```Dockerfile
# Stage 1: Build the application inside the container
FROM openjdk:17-jdk-slim AS builder
# Set the working directory in the container
WORKDIR /app
# Install Git and Gradle (or any dependencies you need to build the app)
RUN apt-get update && \
    apt-get install -y git gradle
# Add an ARG instruction to pass the GitHub token
ARG GITHUB_TOKEN
# Clone the repository into the container using the token
RUN git clone https://${GITHUB_TOKEN}@github.com/britz27/cogsi2425_1201461_1240469_1240448_1211497.git /app
# Set the working directory inside the cloned repo
WORKDIR /app/CA2/CA2_Part2
# Grant execute permissions to the Gradle wrapper script
RUN chmod +x gradlew
# Build the application using Gradle
RUN ./gradlew build --no-daemon
# Stage 2: Use an official OpenJDK runtime as the base image
FROM openjdk:17-jdk-slim
# Set the working directory in the container
WORKDIR /app
# Copy the jar file (assuming it was built successfully)
COPY --from=builder /app/CA2/CA2_Part2/build/libs/basic_demo.jar /app/basic_demo.jar
# Expose port 8080 for the Spring Boot app
EXPOSE 8080
# Run the Spring Boot app
ENTRYPOINT ["java", "-jar", "basic_demo.jar"]
```
Este Dockerfile reutiliza o Dockerfile anterior para a API REST do Spring, mas adiciona um processo de compilação em várias etapas para clonar o código da aplicação a partir de um repositório GitHub privado usando um token GitHub. O processo de compilação é dividido em duas etapas:
- **Etapa 1 (compilador)**: Clona o repositório, compila a aplicação usando Gradle e verifica a criação do ficheiro JAR.
    - A instrução ARG é usada para passar o token do GitHub com segurança durante o processo de compilação.
- O comando git clone busca o repositório usando o token para autenticação.
- O comando de compilação Gradle compila a aplicação e cria o ficheiro JAR.
- **Etapa 2**: Utiliza o tempo de execução oficial do OpenJDK como imagem base e copia o ficheiro JAR compilado da fase de compilação para a imagem final. A instrução EXPOSE expõe a porta 8080 para a aplicação Spring Boot, e a instrução ENTRYPOINT especifica o comando para executar a aplicação Spring Boot.

#### Version 2: Building the Server on the Host and Copying the JAR
A segunda abordagem envolve compilar a aplicação na máquina anfitriã e copiar o ficheiro JAR para a imagem Docker.
Esta solução é apresentada na secção anterior [Packaging Applications into Docker Containers](#packaging-applications-into-docker-containers), onde os ficheiros Dockerfiles criados para a aplicação de chat e a API Spring REST copiam os ficheiros JAR compilados para o contentor.


### Understanding Docker Image Layers and Monitoring
As imagens do Docker são compostas por várias camadas, cada uma representando um conjunto específico de alterações ou instruções na imagem. Compreender as camadas da imagem do Docker é essencial para otimizar o tamanho da imagem, a velocidade de compilação e a eficiência do cache.
Ao compilar imagens do Docker, cada instrução no Dockerfile cria uma nova camada na imagem. As camadas são somente de leitura e podem ser partilhadas entre várias imagens, reduzindo o uso de espaço em disco e melhorando o desempenho da compilação.
Para monitorizar as camadas da imagem Docker e inspecionar o conteúdo de uma imagem, pode-se usar os seguintes comandos:
- `docker history <nome_da_imagem>:<tag_da_imagem>`: exibe o histórico de uma imagem, mostrando as camadas e os comandos usados para compilar a imagem.
  - Por exemplo, `docker history chat-v1` resulta em:
  ```
    IMAGE          CREATED BY                                      SIZE 
    0c4f3b3b4b5d   /bin/sh -c #(nop)  CMD ["java" "-cp" "/app/...   0B
    1e3b3b4b5d4e   /bin/sh -c #(nop) COPY file:8d7b3b4b5d4e1...   45.8MB
    2e3b3b4b5d4e   /bin/sh -c #(nop) WORKDIR /app                  0B
    3e3b3b4b5d4e   /bin/sh -c #(nop)  EXPOSE 59001                 0B
    4e3b3b4b5d4e   /bin/sh -c #(nop)  CMD ["java" "-cp" "/app/...   0B
   ```
- `docker stats <container_name_or_id>` : Exibe o uso de recursos em tempo real de um contentor em execução.
  - e.g., `docker stats chat-server-v1`, resulta em:
  ``` 
    CONTAINER ID   NAME           CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O   PIDS
    1e3b3b4b5d4e   chat-server-v1  0.00%    0B / 0B               0.00%    0B / 0B      0B / 0B    0
   ```
  

### Publishing and Running Docker Images
#### Build a Docker image
`docker build -t <nome_da_imagem>:<tag_da_imagem> .`

`docker build`: este comando é usado para criar uma imagem Docker 
a partir de um Dockerfile (o ficheiro que contém instruções para criar a imagem).

`<nome_da_imagem>`:  é o nome da imagem.

`<image_tag>`: é a tag/versão da imagem. Isso ajuda a distinguir entre diferentes versões da mesma imagem.

`.`: (ponto) Refere-se ao diretório atual e indica ao Docker para usar o Dockerfile nesse diretório para construir a imagem.

#### Run a container

##### Chat
`docker run -p 59001:59001 <chat_image>:<chat_tag>`

`docker run`: Este comando é usado para executar um contentor a partir de uma imagem Docker.

`-p 59001:59001`: Mapeia a porta 59001 do host para a porta 59001 no contentor.

`<chat_image>:<chat_tag>`: Especifica a imagem a ser usada para executar o contentor.

![img.png](images/img.png)

![img_3.png](images/img_3.png)

##### Spring
`docker run -p 8080:8080 <spring_image>:<spring_tag>` 

`docker run`: Este comando é usado para executar um contentor a partir de uma imagem Docker.

`-p 8080:8080`: Esta opção mapeia a porta na máquina host (primeira 8080) para a porta no contentor (segunda 8080).

`<spring_image>:<spring_tag>`: Isto especifica a imagem a ser usada para executar o contentor.

![img_4.png](images/img_4.png)

### Optimize the Dockerfiles

1. **Change of Base Image:**

   - Antes: openjdk:17-jdk-slim
   - Agora: openjdk:17-alpine
   - Motivo:
   A imagem Alpine é significativamente menor porque é uma distribuição Linux minimalista, o que reduz consideravelmente o tamanho final da imagem.

2. **Package Manager Replacement:**
   - Antes: apt-get (usado em imagens baseadas em Debian/Ubuntu).
   - Agora: apk (usado no Alpine).
   - Motivo:
   o apk é o gestor de pacotes do Alpine Linux e permite a instalação de ferramentas como git e gradle com menos sobrecarga.

3. **Cache and Extra Package Optimization:**
   - Removemos o cache e os pacotes desnecessários com o seguinte comando:
```Dockerfile
   RUN apk add --no-cache git gradle
   ```
O sinalizador `--no-cache` impede que o cache temporário do pacote seja guardado no sistema, reduzindo ainda mais o tamanho da imagem.

4. **Cleanup of Intermediate Steps:**
   - Eliminou a necessidade de comandos de limpeza adicionais (como `rm` ou `apt-get clean`) seguindo as melhores práticas da Alpine.
  
Vamos usar a imagem do chat como exemplo:
![img_7.png](images/img_7.png)
Como podemos ver, a imagem otimizada do chat é aquela com o menor tamanho.

## Containerized Environment with Docker Compose
Nesta secção, exploraremos o uso do Docker Compose para criar um ambiente em contentores para executar o servidor de base de dados H2 e a API REST Spring. O Docker Compose é uma ferramenta para definir e executar aplicações Docker com vários contentores usando um ficheiro de configuração YAML.

### Overview of Docker Compose
O Docker Compose simplifica o processo de gerenciamento de aplicações com vários contentores, definindo os serviços, redes e volumes em um único ficheiro de configuração. O ficheiro docker-compose.yml especifica os serviços a serem executados, suas dependências, variáveis de ambiente e outras configurações.

### Setting Up Containers

Crio uma estrutura de diretórios para a configuração do Docker Compose:
```
project-root/
├── docker-compose.yml
├── app/               
│   └── Dockerfile # Dockerfile for the Spring REST API, use version 1 from the previous section because the repository is cloned inside the container
├── db/
│   └── Dockerfile # Dockerfile for the H2 database server
```
#### Database Dockerfile
Dentro da pasta db, crie um Dockerfile para o servidor de base de dados H2 com o seguinte conteúdo:
```Dockerfile
# Base image
FROM openjdk:17-jdk-slim
# Install wget and unzip
RUN apt-get update && apt-get install -y wget unzip curl && rm -rf /var/lib/apt/lists/*
# Define the H2 directory and the zip file to download
ENV H2_DIR="/opt/h2"
ENV H2_ZIP="h2-2019-10-14.zip"
ENV H2_JAR="$H2_DIR/h2/bin/h2*.jar"
# Define the H2 data directory
ENV H2_DATA_DIR="/opt/h2_data"
# Download and unzip the H2 database if not already present
RUN if [ ! -d "$H2_DIR" ]; then \
        echo "H2 directory not found. Downloading H2 database..."; \
        wget http://www.h2database.com/$H2_ZIP -O /tmp/$H2_ZIP && \
        mkdir -p $H2_DIR && \
        unzip -o /tmp/$H2_ZIP -d $H2_DIR && \
        echo "H2 database downloaded and extracted."; \
    else \
        echo "H2 directory already exists. Skipping download."; \
    fi
# Expose ports for H2 TCP and web interfaces
EXPOSE 9092 8082
# Start the H2 server with persistent storage
CMD java -cp $H2_JAR org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -web -webAllowOthers -webPort 8082 -baseDir $H2_DATA_DIR -ifNotExists
```
Este Dockerfile define as etapas para criar uma imagem Docker para o servidor de base de dados H2:
- **FROM**: Especifica a imagem base a ser usada, neste caso, a imagem oficial openjdk:17-jdk-slim.
- **RUN**: instala os pacotes wget, unzip e curl para descarregar e extrair a base de dados H2.
- **ENV**: define variáveis de ambiente para o diretório H2, ficheiro zip, ficheiro JAR, diretório de dados e portas.
- **CMD**: Inicia o servidor H2 com interfaces TCP e web expostas nas portas 9092 e 8082, respetivamente. A opção -baseDir especifica o diretório de dados para armazenamento persistente.
- **EXPOSE**: Expõe as portas 9092 e 8082 para o servidor H2 escutar.

#### Docker Compose Configuration
Crio um ficheiro docker-compose.yml no diretório raiz do projeto com o seguinte conteúdo:
```yaml
services:
  db:
    build:
      context: ./db
    container_name: h2-db
    ports:
      - "9092:9092"
      - "8082:8082"
    volumes:
      - h2_data:/opt/h2_data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8082"]
      interval: 30s
      retries: 3
      start_period: 10s
      timeout: 10s
  web:
    build:
      context: ./app
      args:
        GITHUB_TOKEN: ${GITHUB_TOKEN}
    container_name: web-app
    ports:
      - "8080:8080"
    depends_on:
      - db
    environment:
      - SPRING_DATASOURCE_URL=jdbc:h2:tcp://db:9092//opt/h2_data/test
      - SPRING_DATASOURCE_USERNAME=sa
      - SPRING_DATASOURCE_PASSWORD=
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
      - SPRING_JPA_SHOW_SQL=true
      - SPRING_JPA_PROPERTIES_HIBERNATE_DIALECT=org.hibernate.dialect.H2Dialect
      - SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL=true
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      retries: 3
      start_period: 10s
      timeout: 10s
volumes:
  h2_data:
    name: h2_data
```
Este ficheiro docker-compose.yml define dois serviços:
- **db**: Cria a imagem do servidor de base de dados H2 utilizando o Dockerfile na pasta db. O serviço expõe as portas 9092 e 8082 para as interfaces TCP e web, respetivamente. Também monta um volume chamado h2_data para armazenamento persistente e define uma verificação de integridade para verificar a disponibilidade da interface web.
  - **build**: Especifica o contexto da compilação como a pasta db que contém o Dockerfile.
  - **container_name**: Define o nome do contentor como h2-db.
  - **ports**: Mapeia as portas 9092 e 8082 do contentor para a máquina host.
  - **volumes**: Monta o volume h2_data no diretório /opt/h2_data no contentor para armazenamento persistente.
  - **healthcheck**: Define uma verificação de integridade usando o comando curl para verificar a disponibilidade da interface web.

- **web**: Cria a imagem da API REST Spring usando o Dockerfile na pasta app. O serviço expõe a porta 8080 e depende do serviço db. Define variáveis de ambiente para a configuração da fonte de dados Spring e propriedades Hibernate. Uma verificação de integridade é definida para verificar a disponibilidade da API REST.
  - **build**: Especifica o contexto da compilação como a pasta app que contém o Dockerfile.
  - **args**: Passa o token GitHub como um argumento de compilação para clonar o repositório com segurança.
  - **container_name**: Define o nome do contentor como web-app.
  - **ports**: Mapeia a porta 8080 do contentor para a máquina host.
  - **depends_on**: Especifica que o serviço web depende do serviço db.
  - **environment**: Define variáveis de ambiente para a configuração da fonte de dados Spring e propriedades Hibernate.
  - **healthcheck**: Define uma verificação de integridade usando o comando curl para verificar a disponibilidade da API REST.

- **volumes**: Define um volume nomeado h2_data para armazenamento persistente do diretório de dados do banco de dados H2.

### Testing Container Networking and Health Checks

Para testar a ligação do contentor **web** ao contentor **db**, pode definir a variável de ambiente SPRING_DATASOURCE_URL como `jdbc:h2: tcp://db:9092//opt/h2_data/test`, onde **db** é o nome do host do contentor da base de dados H2, e ela será resolvida para o endereço IP do contentor e conectada ao servidor da base de dados H2.
Para testar a conexão do contentor **db** ao contentor **web**, entre no contentor db e use o comando curl para acessar a API REST:
```bash
docker exec -it h2-db /bin/bash
curl http://web:8080/employees
```
O nome de host **web** será resolvido para o endereço IP do contentor web, e deverá ver a resposta da API REST Spring:
```json
[{"id":1,"name":"Bilbo Baggins","role":"burglar"},{"id":2,"name":"Frodo Baggins","role":"thief"}]
```
As verificações de integridade definidas no ficheiro docker-compose.yml irão verificar periodicamente a disponibilidade dos serviços web e db. As verificações de integridade utilizam o comando curl para testar a ligação às portas e pontos finais especificados. 

### Data Persistence with Docker Volumes
Para manter os dados entre reinicializações do contentor com o Docker Compose, pode usar volumes para armazenar dados fora do sistema de ficheiros do contentor. No ficheiro docker-compose.yml, um volume nomeado h2_data é definido e montado no diretório /opt/h2_data no contentor db para armazenamento persistente do diretório de dados do banco de dados H2.
Para listar volumes com o Docker Compose, pode usar o seguinte comando:
```bash
docker volume ls
```
Para inspecionar um volume, uso:
```bash
docker volume inspect h2_data
```
Os detalhes do volume serão exibidos, incluindo o ponto de montagem na máquina host e o contentor que utiliza o volume, conforme mostrado abaixo:
```json
[
    {
        "CreatedAt": "2024-11-21T23:19:10.974910381Z",
        "Driver": "local",
        "Labels": {},
        "Mountpoint": "/home/user/.local/share/docker/volumes/h2_data/_data",
        "Name": "h2_data",
        "Options": {},
        "Scope": "local"
    }
]
```
Se inspecionar o diretório do ponto de montagem dentro do contentor, encontrará os ficheiros que estão armazenados no volume:
```bash
//Enter the db container with root privileges
docker exec -u root -it h2-db /bin/bash
root@e0dfaa776ede:/# cd /opt/h2_data/
root@e0dfaa776ede:/opt/h2_data# ls
test.mv.db
```

### Publishing

#### Build the images for the containers

`docker-compose build`

Este comando é usado para construir as imagens para os contentores definidos no ficheiro compose.yml (ou compose.yaml, docker-compose.yml, docker-compose.yaml).

O que faz:

- Lê o ficheiro docker-compose.yml para ver como os serviços (contentores) estão configurados.
- Para cada serviço que tenha uma diretiva de compilação, ele tentará compilar a imagem Docker correspondente. Isso inclui buscar o contexto de compilação (geralmente o diretório onde o Dockerfile está localizado) e executar as etapas definidas no Dockerfile (por exemplo, copiar ficheiros, instalar pacotes, definir variáveis de ambiente, etc.).
- Se um serviço usar uma imagem existente (com a diretiva image no docker-compose.yml), o comando docker-compose build não fará nada para esse serviço.

O comando irá construir imagens para os serviços definidos no ficheiro docker-compose.yml.


#### Create and start containers

`docker-compose up`

Este comando é usado para criar e iniciar contentores com base nas imagens definidas ou criadas.

O que faz:

- Lê o ficheiro docker-compose.yml para ver quais serviços estão definidos.
- Para cada serviço, verifica se a imagem Docker existe localmente:
- Se a imagem não existir: o Docker Compose executará automaticamente o docker-compose build para criar a imagem.
- Se a imagem existir: o Docker Compose usará a imagem existente para criar e iniciar o contentor.
Além de criar contentores, o docker-compose up também cria redes, volumes e outras infraestruturas definidas no docker-compose.yml para garantir que os contentores possam interagir corretamente.

Quando executar este comando, o Docker Compose irá:

- Criar e iniciar os contentores definidos no ficheiro docker-compose.yml.
- Exibir os registos dos contentores no terminal. Para parar, pode premir Ctrl+C.

![img_6.png](images/img_6.png)

![img_5.png](images/img_5.png)


### Dockerhub
`https://hub.docker.com/repositories/monteiro20`

### Useful Docker and Docker Compose Commands
Aqui está uma folha de dicas de comandos úteis do Docker e do Docker Compose para gerir contentores, imagens, redes e volumes - [Docker Cheat Sheet](https://dockerlabs.collabnix.com/docker/cheatsheet/).

#### Docker Commands
| **Command** | **Description**                                                                                                                        |
|-------------|----------------------------------------------------------------------------------------------------------------------------------------|
| `docker images` | Lists all local images.                                                                                                                | 
| `docker rmi <IMAGE_ID>` | Removes an image by ID.                                                                                                                | 
| `docker image prune` | Removes unused images.                                                                                                                 | 
| `docker ps`  | Lists running containers. |
| `docker ps -a` |       Lists all containers.                            |
| `docker logs <container_name>` | 	Shows logs from a container.                  | 
| `docker stop <container_id>` |         Stops a running container.                                                      | 
| `docker start -a <container>` |      	Starts a stopped container with logs attached.                                                                                                                                  |
| `docker history <image_name>:<image_id>` |            Shows the history of an image's layers.                       |
| `docker stats` |       Shows real-time resource usage.                           |
| `docker login` |      Logs in to Docker Hub.                             |
| `docker tag` |        Tags an image for pushing to a repository.                           |
| `docker push` |               Pushes an image to Docker Hub.                    |

#### Docker Compose Commands
| **Command**                                | **Description**                                                                                                     |
|--------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| `docker-compose up`                        | Builds, creates, starts, and attaches containers for a defined service.                                             |
| `docker-compose up -d`                     | Starts containers in detached mode (in the background).                                                             |
| `docker-compose down`                      | Stops and removes containers, networks, volumes, and images created by `docker-compose up`.                         |
| `docker-compose build`                     | Builds or rebuilds services defined in the `docker-compose.yml`.                                                    |
| `docker-compose ps`                        | Lists the containers created and managed by the `docker-compose.yml` file.                                          |
| `docker-compose logs`                      | Displays logs from the containers of a service.                                                                     |
| `docker-compose logs -f`                   | Displays logs in real time (follow mode).                                                                           |
| `docker-compose start`                     | Starts services that were previously stopped without rebuilding.                                                    |
| `docker-compose stop`                      | Stops running containers without removing them.                                                                     |
| `docker-compose restart`                   | Restarts all containers in the composition.                                                                         |
| `docker-compose exec <service> <command>` | Executes a command inside a running container for a specific service.                                               |
| `docker-compose config`                    | Validates and displays the configuration file for debugging.                                                        |
| `docker-compose pull`                      | Pulls the latest version of the service images defined in the `docker-compose.yml`.                                 |
| `docker-compose rm`                        | Removes stopped service containers.                                                                                 |
| `docker-compose run <service> <command>`  | Runs a one-off command in a new container of the specified service.                                                 |



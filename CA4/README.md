# CA4 - Gestão de Configuração

Os seguintes passos delineiam a implementação da solução:
### Criar um inventário
1. Criar um ficheiro de inventário, hosts.ini.
2. Definir as VMs no ficheiro de inventário.
    ```ini
    [app]
    192.168.56.12 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/app_key

    [db]
    192.168.56.11 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/db_key
    ```
O ficheiro de inventário define dois grupos, app e db, com os endereços IP das VMs e os ficheiros de chave privada SSH para autenticação.
Estes ficheiros de chave são gerados pelo Vagrant e são utilizados para autenticar o nó de controlo Ansible com as VMs.

### Passos para o playbook da app
1. Criar um ficheiro yml, app.yml.

2. Traduzir a implementação anterior do CA3/part2 para o playbook. As próximas tarefas são a tradução da implementação anterior do provision_app.sh para o playbook.
   1. **Instalar as dependências necessárias.**
      ```yml
           - name: Install dependencies
             apt:
              name:
               - openjdk-17-jdk
               - git
               - netcat-openbsd
               - curl
               - wget
               - unzip
               - net-tools
             state: present
      ```
   2. **Clonar a aplicação Spring Boot do GitHub.**
      ```yml
      - name: Clone Spring Boot application repository
        shell: |
         git clone https://{{ lookup('env', 'GITHUB_TOKEN') }}@github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git /home/vagrant/app
        args:
         creates: /home/vagrant/app
        become: yes
        become_user: vagrant
        environment:
         GIT_TERMINAL_PROMPT: '0'
        register: git_clone
        failed_when: git_clone.rc != 0 and git_clone.rc != 128
       ```
   3. **Criar o diretório application.properties**
      ```yml
      - name: Create application properties directory
        file:
         path: "/home/vagrant/app/CA2-part2/tut-gradle/src/main/resources"
         state: directory
         mode: '0755'
      ```
   4. **Criar o ficheiro application.properties**
      ```yml
      - name: Configure application.properties
       copy:
       dest: "/home/vagrant/app/CA2-part2/tut-gradle/src/main/resources/application.properties"
       content: |
       # H2 Database Configuration (Remote DB Server)
       spring.datasource.url=jdbc:h2:tcp://192.168.56.11:9092/home/vagrant/h2_data/jpadb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE
       spring.datasource.driverClassName=org.h2.Driver
       spring.datasource.username=sa
       spring.datasource.password=
 
        # JPA Configuration
        spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
        spring.jpa.hibernate.ddl-auto=update
  
        # H2 Console Configuration
        spring.h2.console.enabled=true
        spring.h2.console.path=/h2-console
        spring.h2.console.settings.web-allow-others=true
  
        # Spring Data REST
        spring.data.rest.base-path=/api
        ```
   5. **Aguardar que a base de dados esteja em funcionamento.**
   ```yml
   - name: Wait for DB server to be ready
     wait_for:
       host: "192.168.156.11"
       port: "9092"
       delay: 5
       timeout: 300
       state: started
   ```
   6. **Tornar o diretório de compilação da aplicação executável**
    ```yml
   - name: Build the application
     shell: "./gradlew clean build -x test"
     args:
      chdir: "/home/vagrant/app/CA2-part2/tut-gradle"
     become: yes
     become_user: vagrant
     environment:
      HOME: /home/vagrant
    ```
   7. **Iniciar a aplicação.**
   ```yml
   - name: Start Spring Boot application
     shell: "nohup ./gradlew bootRun > /home/vagrant/spring-app.log 2>&1 & echo $! > /home/vagrant/spring-app.pid"
     args:
      chdir: "/home/vagrant/app/CA2-part2/tut-gradle"
     become: yes
     become_user: vagrant
     environment:
      HOME: /home/vagrant
   ```

   8. **Health-Check da aplicação**
   ```yml
   - name: Health check - Verify Spring Boot is responding
     uri:
      url: http://localhost:8080
      method: GET
      status_code: 200
     retries: 5
     delay: 5
     register: health_check
     until: health_check.status == 200
   ```

### Passos para o playbook da db
1. Criar um ficheiro yml, db.yml.
2. Traduzir a implementação anterior do CA3/part2 para o playbook. As próximas tarefas são a tradução da implementação anterior do provision_db.sh para o playbook.
    1. **Instalar as dependências necessárias.**
       ```yml
        - name: Install OpenJDK 17, unzip, and net-tools
          apt:
           name:
            - openjdk-17-jdk
            - unzip
            - net-tools
          state: present
        ```
    2. **Verificar se o diretório H2 existe**
       ```yml
         - name: Check if H2 directory exists
           stat:
             path: /opt/h2
           register: h2_dir
       ```
    3. **Descarregar e extrair a base de dados H2**
       ```yml
       - name: Download and extract H2 database
         when: not h2_dir.stat.exists
         block:
          - name: Download H2 database JAR
            get_url:
             url: https://repo1.maven.org/maven2/com/h2database/h2/2.1.214/h2-2.1.214.jar
             dest: /opt/h2.jar
             mode: '0644'
          
          - name: Create H2 directory
            file:
              path: /opt/h2
              state: directory
              mode: '0755'
      
          - name: Move H2 JAR to directory
            command: mv /opt/h2.jar /opt/h2/h2.jar
            args:
              creates: /opt/h2/h2.jar
       ```

    4. **Iniciar a base de dados H2**
        ```yml
         - name: Start H2 database
           shell: |
            nohup java -cp /opt/h2/h2.jar org.h2.tools.Server \
             -tcp -tcpAllowOthers -tcpPort 9092 \
             -web -webAllowOthers -webPort 8082 \
             -baseDir /home/vagrant/h2_data \
             -ifNotExists > /home/vagrant/h2-server.log 2>&1 &
             echo $! > /home/vagrant/h2-server.pid
           args:
            chdir: /home/vagrant
            executable: /bin/bash
           become: yes
           become_user: vagrant
           environment:
            HOME: /home/vagrant
        ```
    5. **Instalar UFW (Uncomplicated Firewall)**
        ```yml
         - name: Install UFW (Uncomplicated Firewall)
           apt:
             name: ufw
             state: present
        ```
    6. **Definir política padrão do UFW para negar conexões de entrada**
        ```yml
         - name: Set UFW default policy to deny incoming connections
           ufw:
           default: deny
           direction: incoming
        ```
    7. **Definir política padrão do UFW para permitir conexões de saída**
         ```yml
            - name: Set UFW default policy to allow outgoing connections
              ufw:
              default: allow
              direction: outgoing
         ```
    8.  **Permitir conexões de entrada na porta 9092**
          ```yml
          - name: Allow connections to H2 database port (9092) from app VM (192.168.56.12)
            ufw:
            rule: allow
            proto: tcp
            from_ip: 192.168.56.12
            port: "9092"  # Quoted to avoid type warning
          ```
    9. **Ativar UFW**
         ```yml
         - name: Enable UFW
           ufw:
           state: enabled
          ```

    10. **Verificar que o socket ou porta da base de dados H2 está aberto e a aceitar conexões**
         ```yml
        - name: Health check - Verify H2 database port is accepting connections
          wait_for:
           host: 0.0.0.0
           port: 9092
           state: started
           timeout: 10
          register: db_health
          retries: 3
          delay: 5
          until: db_health is succeeded
          
        - name: Health check - Verify H2 web console is accessible
          wait_for:
           host: 0.0.0.0
           port: 8082
           state: started
           timeout: 10
          register: console_health
          retries: 3
          delay: 5
          until: console_health is succeeded
        ```

### Playbooks
### Executar os playbooks
Os playbooks podem ser executados localmente usando os seguintes comandos, mas é necessário ter o ansible instalado na máquina local:
1. Executar primeiro o playbook da db para configurar a base de dados H2.
    ```bash
    ansible-playbook -i hosts.ini db.yml
    ```
2. Executar o playbook da app para configurar a aplicação Spring Boot.
    ```bash
    ansible-playbook -i hosts.ini app.yml
    ```
Outra forma de usar os playbooks é implementá-los num ficheiro vagrant. Isto pode ser feito reutilizando o Vagrantfile do CA3/part2 e modificando a configuração como mostrado abaixo:

1. Adicionar as seguintes linhas ao Vagrantfile para configurar as chaves ssh, tal como no CA3/part2:
    ```ruby
        Vagrant.configure("2") do |config|
          # Provisioning private key for app
          config.vm.provision "file",
            source: "~/.ssh/app_key",
            destination: "/home/vagrant/.ssh/app_key"
        
          # Provisioning private key for db
          config.vm.provision "file",
            source: "~/.ssh/db_key",
            destination: "/home/vagrant/.ssh/db_key"
        
          # SSH private key paths
          config.ssh.private_key_path = [
            "~/.vagrant.d/insecure_private_key",
            "~/.ssh/app_key",
            "~/.ssh/db_key"   
          ]
    ```
2. Adicionar a seguinte pasta sincronizada para guardar os dados da db:
    ```ruby
       config.vm.synced_folder "./h2_data", "/home/vagrant/h2_data"
    ```
3. Adicionar as seguintes linhas ao Vagrantfile para executar o playbook da db:
    ```ruby
    config.vm.define "db" do |db|
     db.vm.box = "bento/ubuntu-22.04"
     db.vm.network "private_network", ip: "192.168.56.11"
     db.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = 1
     end
     db.vm.provision "file",
      source: "~/.ssh/db_key.pub",
      destination: "~/.ssh/authorized_keys"
     db.vm.provision "shell", inline: <<-SHELL
      chmod 600 /home/vagrant/.ssh/db_key
     SHELL
     db.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "db_playbook.yml" #explained later
      ansible.inventory_path = "hosts.ini"
      ansible.extra_vars = { host: "db" }
      ansible.compatibility_mode = "2.0"
      ansible.raw_arguments = ["--ssh-extra-args='-o StrictHostKeyChecking=no'"]
     end
    end
    ```

4. Adicionar as seguintes linhas ao Vagrantfile para executar o playbook da app:
    ```ruby
      config.vm.define "app" do |app|
       app.vm.box = "bento/ubuntu-22.04"
       app.vm.network "private_network", ip: "192.168.56.12"
       app.vm.network "forwarded_port", guest: 8080, host: 8080
       app.vm.provider "virtualbox" do |vb|
         vb.memory = "2048"
         vb.cpus = 2
       end
       app.vm.provision "file",
           source: "~/.ssh/app_key.pub",
           destination: "~/.ssh/authorized_keys"
       app.vm.provision "shell", inline: <<-SHELL
        chmod 600 /home/vagrant/.ssh/app_key
       SHELL
       app.vm.provision "ansible_local" do |ansible|
         ansible.playbook = "app_playbook.yml" #explained later
         ansible.inventory_path = "hosts.ini"
         ansible.extra_vars = { host: "app" }
         ansible.compatibility_mode = "2.0"
         ansible.raw_arguments = ["--ssh-common-args='-o StrictHostKeyChecking=no'"]
       end
     end
   ```
No Vagrantfile, as VMs db e app são definidas, e os playbooks db e app são provisionados às respetivas VMs. As chaves SSH também são provisionadas às VMs para permitir que o Ansible se conecte a elas. O modo de compatibilidade é definido como 2.0 para evitar erros, e os argumentos SSH são especificados para evitar erros de known_hosts.
Pode-se notar que é usado ansible_local, isto é feito uma vez que instalar o Ansible no host local é difícil, por isso é melhor usar o provisionador ansible_local instalado nas VMs pelo Vagrant.

### Testar a solução
1. Executar o Vagrantfile para criar as VMs e provisioná-las com os playbooks.
    ```bash
    vagrant up
    ```
2. Aceder à aplicação Spring Boot abrindo um navegador web e navegando para http://192.168.56.12:8080
3. Devido às regras de firewall configuradas pelo UFW, a consola da base de dados H2 não é acessível a partir da máquina host. Para modificar este comportamento, pode adicionar uma regra para permitir conexões à porta 8082 no playbook da db. Após adicionar a regra, pode aceder à consola da base de dados H2 abrindo um navegador web e navegando para http://192.168.56.12/8082:

## Aplicar Políticas de Passwords Complexas com Configuração PAM Usando Ansible
Para reforçar a segurança do sistema, é essencial aplicar regras de complexidade de passwords como comprimento mínimo, tipos de caracteres obrigatórios e limites de tentativas. Este guia aproveita o módulo pam_pwquality para implementar estas regras e usa o Ansible para automação.

### Detalhes do Playbook:
1. **Instalar Dependências do PAM**: A primeira tarefa garante que o módulo PAM necessário, libpam-pwquality, está instalado nos sistemas alvo.
    ```yml
    - name: Install PAM dependencies
      apt:
        name: "libpam-pwquality"
        state: present
        update_cache: yes
   ```
   **O que faz**:

    - Instala libpam-pwquality, que fornece aplicação avançada de qualidade de passwords.
    - Atualiza a cache de pacotes para garantir que a versão mais recente é instalada.

2. **Configurar Regras do pam_pwquality**: A segunda tarefa modifica o ficheiro /etc/pam.d/common-password para aplicar complexidade de passwords.
    ```yml
    - name: Configure pam_pwquality
      lineinfile:
       path: "/etc/pam.d/common-password"
       regexp: "pam_pwquality.so"
       line: "password required pam_pwquality.so minlen=12 lcredit=-1 ucredit=-1 dcredit=-1 ocredit=-1 retry=3 enforce_for_root"
       state: present
      ```
   **Explicação das Regras**:

    - ***minlen***=12: As passwords devem ter pelo menos 12 caracteres.
    - ***minclass***=3: pelo menos 3 de 4 classes de caracteres (maiúsculas, minúsculas, dígitos, símbolos)
    - ***lcredit***=-1: Requer pelo menos uma letra minúscula.
    - ***ucredit***=-1: Requer pelo menos uma letra maiúscula.
    - ***dcredit***=-1: Requer pelo menos um dígito.
    - ***ocredit***=-1: Requer pelo menos um carácter especial.
    - ***usercheck***=1: não permite passwords contendo o nome de utilizador ou partes dele.
    - ***dictcheck***=1: rejeita palavras comuns de dicionário.
    - ***enforce_for_root***: Aplica estas regras mesmo para o utilizador root.


3. **Prevenir a reutilização das últimas cinco passwords**:
    ```yml
    - name: Ensure pam_unix prevents password reuse
      lineinfile:
        path: "/etc/pam.d/common-password"
        regexp: "pam_unix.so"
        line: "password sufficient pam_unix.so sha512 shadow remember=5"
        state: present
      ```

4. **Garantir que a conta é bloqueada durante dez minutos após cinco tentativas de login falhadas consecutivas**:
    ```yml
    - name: Configure account lockout policy (faillock)
      lineinfile:
        path: "/etc/pam.d/common-auth"
        insertafter: "pam_env.so"
        line: |
          auth required pam_faillock.so preauth silent deny=5 unlock_time=600
          auth [default=die] pam_faillock.so authfail deny=5 unlock_time=600
        state: present
      ```

### Executar o playbook
Os playbooks podem ser executados localmente usando os seguintes comandos, mas é necessário ter o ansible instalado na máquina local:

1. Executar o playbook usando o seguinte comando:
    ```bash
    ansible-playbook configure_pam.yml -i Vagrantfile
    ```

### Benefícios de Usar Configuração PAM com Ansible
- **Automação**: Aplicar políticas de passwords em múltiplos sistemas com esforço mínimo.
- **Consistência**: Garante configurações de segurança uniformes em todos os servidores.
- **Eficiência**: Reduz a configuração manual, minimizando erros e poupando tempo.


## Configurar Acesso Seguro à Aplicação e Base de Dados para o Grupo de Developers Usando Ansible

Num ambiente de desenvolvimento seguro, controlar o acesso aos recursos da aplicação e base de dados é vital. Este guia usa o Ansible para automatizar a criação de um grupo developers, adicionar um utilizador a esse grupo e aplicar acesso restrito a diretórios-chave.

### Detalhes do Playbook
1.  **Criar o Grupo Developers**:
    A primeira tarefa garante a existência de um grupo developers, simplificando a gestão de acesso para múltiplos utilizadores.
    ```yml
    - name: Create developers group
      group:
        name: developers
        state: present
      ```   

2.  **Adicionar o Utilizador devuser ao Grupo Developers**:

    Criar um novo utilizador, devuser, e atribuí-lo ao grupo developers.
    ```yml
    - name: Create devuser user and add to developers group
      user:
        name: devuser
        groups: developers
        append: yes
        state: present
    ```
    #### Pontos-Chave
    - **append: yes:**:
      Garante que o utilizador permanece parte de quaisquer grupos previamente atribuídos enquanto é adicionado ao developers.
    - Esta tarefa garante atribuição de funções sem problemas sem sobrescrever outras associações de grupos do utilizador.


3. **Tornar o diretório da aplicação spring e da base de dados acessível apenas aos membros do grupo developers**:

   ```yml
    - name: Set ownership of app directory to developers group
      file:
        path: /home/vagrant/app
        owner: devuser
        group: developers
        mode: '0750' #means only owner (vagrant) and group (developers) can access
        recurse: yes
      become: yes
      when: "'app' in group_names"
      
    - name: Set ownership of h2_data directory to developers group
      file:
        path: /home/vagrant/h2_data
        owner: vagrant
        group: developers
        mode: '0750'
        recurse: yes
      become: yes
      when: "'db' in group_names" # Ignores errors if the directories don't exist    
   ```
   #### Detalhes
    - **mode: '0750'**:
      Fornece permissões de leitura, escrita e execução para o proprietário, permissões de leitura e execução para o grupo, e sem acesso para outros.
    - **recurse: yes**:
      Itera sobre os diretórios especificados.

## Adicionar os Playbooks de Criar Utilizadores e PAM ao Vagrantfile
Para integrar os playbooks create_users.yml e configure_pam.yml no ficheiro vagrant, os seguintes passos podem ser seguidos:
1. **Criar um novo playbook app_playbook.yml**:
    - Neste novo playbook usar o módulo import_tasks para incluir os playbooks app, create_users.yml e configure_pam.yml, como mostrado abaixo:
        ```yml
       - hosts: app
         become: yes
         tasks:
          - import_tasks: app.yml
          - import_tasks: configure_pam.yml
          - import_tasks: configure_users.yml
          - import_tasks: configure_permissions.yml
       ```
2. **Criar um novo playbook db_playbook.yml**:
    - Neste novo playbook usar o módulo import_tasks para incluir os playbooks db, create_users.yml e configure_pam.yml, como mostrado abaixo:
       ```yml
       - hosts: db
         become: yes
         tasks:
       - import_tasks: db.yml
       - import_tasks: configure_pam.yml
       - import_tasks: configure_users.yml
       - import_tasks: configure_permissions.yml
       ```
3. **Modificar o Vagrantfile**:
    - Modificar as linhas onde app.yml e db.yml são provisionados para incluir os novos playbooks, como mostrado abaixo:
      ```ruby
      ansible.playbook = "db_playbook.yml"
      ansible.playbook = "app_playbook.yml"
      ```
4. **Executar o ficheiro vagrant**:
    - Executar o ficheiro vagrant para criar as VMs e provisioná-las com os playbooks.
      ```bash
       vagrant up
      ```

### Testar os Playbooks de Configuração PAM e Utilizadores

1. **Aceder à Conta devuser**:
   Para mudar para a conta devuser com privilégios de superutilizador, usar o seguinte comando:
    ```bash
    sudo -su devuser
    ```
2. **Listar Conteúdos do Diretório em /home/vagrant/app**:
   Para inspecionar os ficheiros e diretórios em /home/vagrant/app, usar o seguinte comando:
    ```bash
    ls -la /home/vagrant/app/
    ```
   A saída esperada deve mostrar as permissões, propriedade e grupos para cada item dentro do diretório /home/vagrant/app.

4. **Verificar Grupo de Utilizador e Informação da Conta**:
   Estes comandos mostrarão a informação do grupo e detalhes da conta de utilizador para devuser. O grupo developers deve listar devuser como membro, com o GID (Group ID) e UID (User ID) esperados especificados na saída.

5. **Aplicar Requisitos de Complexidade de Password**:
   Para garantir políticas de passwords fortes, o sistema está configurado para usar libpam-pwquality. Este pacote aplica requisitos de complexidade nas passwords dos utilizadores. Para verificar se libpam-pwquality está instalado, usar:
    ```bash
    dpkg -l | grep libpam-pwquality
    ```

6. **Alterar Password para devuser**:
   Para aplicar estas políticas de passwords, tentar alterar a password de devuser usando:
    ```bash
    sudo passwd devuser
    ```
   Se a password inserida não cumprir os requisitos de complexidade, será mostrado um erro, indicando os critérios específicos que não foram cumpridos. Isto garante que todas as passwords dos utilizadores estão alinhadas com as políticas de segurança do sistema.




## Ansible Alternative

### Salt (SaltStack)
## Análise [Ansible versus Salt]

O **Salt** e o **Ansible** são ambos ferramentas de gestão de configuração, mas apresentam arquiteturas e casos de utilização distintos:

- **Salt**: É uma ferramenta de gestão de configurações e execução remota que utiliza uma arquitetura *master-minion* com comunicação via **ZeroMQ**. O Salt foi construido para a exec>
- **Ansible**: É uma ferramenta de automação de configurações que utiliza uma arquitetura sem agentes (**agentless**), baseada em **SSH**. O Ansible é ideal para implementações mais s>

| **Aspeto**                        | **Ansible**                                                                                              | **Salt**                              |
|-----------------------------------|----------------------------------------------------------------------------------------------------------|---------------------------------------|
| **Arquitetura**                   | Sem agentes (*agentless*) utilizando SSH para ligar aos nós geridos.                                       | Baseada em agentes e requer *salt-mi>
| **Protocolo de Comunicação**      | SSH.                                                                               |  ZeroMQ. |
| **Velocidade de Execução**        | Sequencial por defeito.                                                                                  | Paralela por defeito.                 |
| **Escalabilidade**                | Boa para implementações pequenas a médias.                                                               | Excelente escalabilidade.             |
| **Linguagem de Configuração**     | YAML em playbooks imperativos.                                                                         | YAML em ficheiros de estado declarativos>
| **Gestão de Estado**              | *Stateless* (não mantém estado).                                                                         | *Stateful*, mantendo informação sobre >
| **Idempotência**                  | Incorporada — os módulos são desenhados para serem idempotentes.                                         | Incorporada.                          |
| **Gestão de Dependências**        | Básica (através de *handlers* e condições *when*).                                                       | Avançada (comandos como *require*, *wa>

---

## Implementação

A configuração é definida numa série de ficheiros de estado do Salt (`.sls`) e é gerida por um *Vagrantfile*.  
Esta implementação utiliza uma arquitetura **Salt sem master** (*masterless*), onde cada máquina virtual (*minion*) é configurada com base num conjunto de ficheiros de estado.

### Vagrantfile
Alteramos o ficheiro para usar salt como provision 
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  config.vm.synced_folder "salt/", "/srv/salt"

  #DB vm configuration...

    # Salt provisioner for DB
    db.vm.provision :salt do |salt|
      salt.minion_config = "salt/minion"
      salt.run_highstate = true
      salt.verbose = true
      salt.colorize = true
    end
  end

  # Application VM configuration ...

    # Salt provisioner for App
    app.vm.provision :salt do |salt|
      salt.minion_config = "salt/minion" 
      salt.run_highstate = true
      salt.verbose = true
      salt.colorize = true
    end
  end
end

```
### minion
O ficheiro de configuração para o serviços de minions.É aqui que definimos como os minions vão operar,onde encontrar as instruções,etc...

```yaml

masterless: true
file_client: local

# Tell the minion where to find the state files
file_roots:
  base:
    - /srv/salt
```

### top.sls

```yaml
base:
  'db':
    - fix_minion
    - db
    - pam
    - users
    - health.db

  'app':
    - fix_minion
    - app
    - pam
    - users
    - health.app
```
Este ficheiro define os ficheiros de estado que cada  minion irá aplicar.

### app.sls
Este ficheiro contem as instruções para dar setup à app,fazendo com que os packages necessários são instalados e que a app está a correr.

```yaml

install_java_and_git:
  pkg.installed:
    - pkgs:
      - openjdk-17-jdk
      - git
    - require:
      - pkg: update_apt_cache

clone_spring_app_repo:
  git.latest:
    - name: "https://github.com/pedroteixeira80/cogsi2526-1201264-1210901-1210902.git"
    - target: /home/vagrant/app
    - user: vagrant
    - rev: HEAD
    - require:
      - pkg: install_java_and_git

wait_for_db_port:
  network.wait_for_port:
    - host: 192.168.56.11
    - port: 9092
    - timeout: 300
        ...
start_spring_boot_app:
  cmd.run:
    - name: "nohup ./gradlew bootRun > spring_app.log 2>&1 &"
    - cwd: /home/vagrant/app/CA2-part2/tut-gradle
    - user: vagrant
    - unless: "ss -tuln | grep ':8080'"
    - require:
      - network: wait_for_db_port
      - file: make_gradlew_executable
```

A cmd.run é um dos poucos módulos que não é idempotente e para tal usamos o unless que faz com o que comando não corra caso a condição(neste caso o port estar em uso) seja verdade.
Devido à natureza paralela do *Salt* usamos o require para garantir a ordem correta dos módulos.

# db.sls
Este ficheiro faz o setup da db e das regras de firewall.
```yaml
          ....
install_h2_database:
  archive.extracted:
    - name: /opt/h2
    - source: http://www.h2database.com/h2-2019-10-14.zip
    - user: root
    - group: root
    - if_missing: /opt/h2/h2/bin/h2.jar 
    - skip_verify: True
    - require:
      - pkg: install_db_packages

start_h2_server:
  cmd.run:
    - name: "nohup java -cp /opt/h2/h2/bin/h2*.jar org.h2.tools.Server -tcp -tcpAllowOthers -tcpPort 9092 -web -webAllowOthers -webPort 8082 -baseDir /home/vagrant/h2_data -ifNotExists > /dev/null 2>&1 &"
    - user: vagrant
    - unless: "netstat -tuln | grep ':9092'"
    - require:
      - archive: install_h2_database
install_ufw:
  pkg.installed:
    - name: ufw

configure_ufw_rules:
  cmd.run:
    - name: |
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow from 192.168.56.12 to any port 9092 proto tcp comment 'Allow app server'
        echo "y" | ufw enable
    - unless: "ufw status | grep '9092/tcp.*192.168.56.12.*ALLOW IN'"
    - require:                                                          
      - pkg: install_ufw
```

### Pam.sls
Este ficheiro configura o PAM para enforçar uma politica de password forte.
```yaml

install_pam_libraries:
  pkg.installed:
    - pkgs:
      - libpam-pwquality
      - libpam-modules

configure_common_password_pam:
  file.prepend:
    - name: /etc/pam.d/common-password
    - text: 'password        requisite                       pam_pwquality.so retry=3 minlen=12 minclass=3 remember=5 reject_username'
    - require:
      - pkg: install_pam_libraries

configure_account_lockout:
  file.prepend:
    - name: /etc/pam.d/common-auth
    - text:
      - 'auth    required                        pam_tally2.so onerr=fail deny=5 unlock_time=600'
    - require:
      - pkg: install_pam_libraries   
```

File.prepend é um exemplo da idempotência do Salt,este é um módulo que adiciona texto ao inicio de um ficheiro mas que verifica o estado do ficheiro(neste caso se o texto que
queremos adicionar já está no inicio) e não faz nada caso já esteja no estado pretendido.

### configure_users.sls
Este ficheiro cria o user e grupo pretendido e restringe o acesso ao diretório.

```yaml
create_developers_group:
  group.present:
    - name: developers

create_devuser:
  user.present:
    - name: devuser
    - groups:
      - developers
    - require:
      - group: create_developers_group

restrict_app_dir_access:
  file.directory:
    - name: /home/vagrant/app
    - user: devuser
    - group: developers
    - mode: '770' 
    - require:
      - user: create_devuser

restrict_h2_data_dir_access:
  file.directory:
    - name: /home/vagrant/h2_data
    - user: devuser
    - group: developers
    - mode: '770'
    - makedirs: True
    - require:
      - user: create_devuser
```

As permissões escolhidas para o diretório foram 770 dando permissões de escrita leitura e execução a todos os membros do grupo.Dependendo do projeto outras permissões podiam
ser escolhidos como 750 caso o grupo não podesse ter acesso direto a alterar as aplicações.

### Health Checks
Estes ficheiros foram criados segundo as intruções para garantir que os serviçoes estão a correr corretamente.

healthDB:
```yaml
 check_h2_database_port:
  cmd.run:
    - name: "ss -ltn | grep ':9092'"
    - require:
      - cmd: start_h2_server
```

Verifica se o port está em uso

healthAPP:
```yaml
check_spring_app_health:
  http.query:
    - name: http://localhost:8080/actuator/health
    - status: 200
    - match: '"status":"UP"'
    - require:
      - cmd: start_spring_boot_app
```
Mandamos um request para o actuator/health endpoint que é um endpoint do spring boot para verificar o estado.

Ambos estes módulos dependem de módulos de outros ficheiros mas no salt as dependências são globais para cada minion.

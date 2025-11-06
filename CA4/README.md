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

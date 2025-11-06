
update_apt_cache:
  pkg.uptodate:
    - refresh: True

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

# Create the application.properties file with database connection details
configure_application_properties:
  file.managed:
    - name: /home/vagrant/app/CA2-part2/tut-gradle/src/main/resources/application.properties
    - contents: |
        spring.datasource.url=jdbc:h2:tcp://192.168.56.11:9092/home/vagrant/h2_data/test
        spring.datasource.driverClassName=org.h2.Driver
        spring.datasource.username=sa
        spring.datasource.password=
        spring.datasource.platform=h2
        spring.h2.console.enabled=true
        spring.h2.console.path=/h2-console
        spring.jpa.show-sql=true
        spring.jpa.hibernate.ddl-auto=update
    - user: vagrant
    - group: vagrant
    - mode: '0644'
    - makedirs: True
    - require:
      - git: clone_spring_app_repo

# Make the Gradle wrapper executable
make_gradlew_executable:
  file.managed:
    - name: /home/vagrant/app/CA2-part2/tut-gradle/gradlew
    - mode: '0755'
    - user: vagrant
    - require:
      - git: clone_spring_app_repo

# Build and start the Spring Boot application, only if not already running
start_spring_boot_app:
  cmd.run:
    - name: "nohup ./gradlew bootRun > spring_app.log 2>&1 &"
    - cwd: /home/vagrant/app/CA2-part2/tut-gradle
    - user: vagrant
    - unless: "ss -tuln | grep ':8080'"
    - require:
      - network: wait_for_db_port
      - file: make_gradlew_executable

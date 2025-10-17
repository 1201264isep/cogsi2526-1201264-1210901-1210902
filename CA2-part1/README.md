


# cogsi2526-1201264-1210901-1210902
## CA2 Part 1
### Self-evaluation
Hélder Rocha (1210901) - 33,33%<br>
Pedro Teixeira (1210902) - 33,33%<br>
Francisco Gouveia(1201264) - 33,33%
## Technical Report

- ### Description of analysis
Analisámos os objetivos definidos para a Parte 1 da CA2 e concluímos que seria necessário utilizar diversos comandos Git e configurar corretamente o Gradle, de forma a praticar a criação e gestão de tarefas que requerem a utilização do mesmo.

### Implementation
- 
#### Part 1
- 1 - Criamos o diretório CA2-part1 (mkdir CA2-part1) e copiamos para lá a aplicação exemplo fornecida.
- 2 - Fizemos commit do código inicial e adicionamos a tag ca2-1.1.0.
- 3 - Experimentamos a aplicação (build, run the server e run a client) para verificar que estava tudo a funcionar devidamente.
- 4 - Criámos o branch ca2-part1 para o desenvolvimento da primeira parte da CA2.
- 5 - Adicionámos o diretório src/test para incluir o teste unitário.
- 6 - Criámos a classe ChatClientTest, contendo um teste unitário simples sobre a classe ChatClient.
- 7 - Adicionamos ao ficheiro build.gradle na secção *dependencies* as dependências necessárias (JUnit) para permitir a criação e execução de testes unitários. Adicionamos também a secção *test* configurando o Gradle para utilizar a JUnit Platform.
- 8 - Fizemos novamente build (gradle build) e corremos o teste unitário, verificando o seu sucesso.
- 9 - Fizemos commit (git commit -a -m "") e push (git push) destas alterações.
- 10 - Criamos a issue "Create copy task".
- 11 - Adicionamos ao ficheiro build.gradle a task "copy", que consiste em copiar o diretório "src" para um novo "backup". Adicionamos esta task ao grupo "Backup", para que ao utilizar o comando "gradle tasks", o output seja mais organizado (por grupo).
- 12 - Seguindo a mesma lógica da tarefa anterior, adicionámos a task "zip" para criar um ficheiro ZIP do diretório "backup". Esta task foi também adicionada ao grupo "Backup". Destaca-se nesta task a linha dependsOn copy, que garante que, antes de o Gradle executar a task zip, a task copy é executada com sucesso.
- 13 - Por fim executamos o comando “./gradlew –q javaToolchain”. O output foi o seguinte:


Options<br>
  | Auto-detection:     Enabled<br>
  | Auto-download:      Enabled
   <br><br>
Amazon Corretto JDK 17.0.16+8-LTS<br>
  | Location:           /Users/pedroteixeira/Library/Java/JavaVirtualMachines/corretto-17.0.16/Contents/Home<br>
  | Language Version:   17<br>
  | Vendor:             Amazon Corretto<br>
  | Architecture:       aarch64<br>
  | Is JDK:             true<br>
  | Detected by:        Current JVM
  <br><br>
Homebrew JDK 21.0.8<br>
  | Location:           /opt/homebrew/Cellar/openjdk@21/21.0.8/libexec/openjdk.jdk/Contents/Home<br>
  | Language Version:   21<br>
  | Vendor:             Homebrew<br>
  | Architecture:       aarch64<br>
  | Is JDK:             true<br>
  | Detected by:        MacOS java_home
  <br><br>

**Significado**: 
<br>O Gradle mostra informações sobre a Java Toolchain, que é o mecanismo que garante que o projeto usa sempre a versão correta do JDK, mesmo que existam várias versões instaladas no computador.
<br><br>Na parte "Options", "Auto-detection: Enabled" significa que o Gradle deteta automaticamente os JDKs instalados no sistema e "Auto-download: Enabled" garante que O Gradle pode transferir automaticamente a versão de JDK necessária, se não estiver instalada.
<br><br>Na secção seguinte mostra a versão do JDK que o Gradle está realmente a usar neste projeto, de acordo com o que está no ficheiro build.gradle.<br>
java {<br>
toolchain {<br>
languageVersion = JavaLanguageVersion.of(17)<br>
}<br>
}<br>


Na última parte do output é possível ver que o Gradle detetou também outra versão do JDK (a 21), instalada através do Homebrew, mas essa não está a ser utilizada no projeto.
<br><br>

#### Part 2

- 14 -
- 15 -
- 16 -
- 17 - 
- 18 - 
- 19 - 
- 20 - 
- 21 - 
- 22 - 
- 23 - 
- 24 - 
- 25 - 
- 26 - 
- 27 -  
- 28 - 
- 29 - 
- 30 - 

#### Alternativas
### Ant
## Comparison Between Gradle and Ant

Gradle and  Ant are build automation tools for Java allowing to standardize builds and make them faster.
Ant is one of the oldest build tools known for it's highly controllable way to define builds being still used in simpler projects.
Gradle is more modern simplified approach focused on scripting that allows for more advanced features.

| **Factors**               | **Gradle**                                                                                                                      | **Ant**                                                                                         |
|:--------------------------|:--------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------|
| **Configuration**         | Groovy or Kotlin — relatibly concise and easier to understand.                                                                  | XML — very verbose,everything has to be typed                                                   |
| **Dependency Management** | Built-in dependency resolution                                                                                                  | No native dependency management but Ivy is used                                                                |
| **Tasks**                 | very flexible and easy to create custom tasks                                                                                   | More complext to configure                                                                      |
| **Performance**           | Incremental builds and caching reduce work and speed up repeated builds.                                                        | No built-in incremental build/caching         |

## Implementation
# Part 1
To start we need to convert the gradle files to the equivalent files.Gradle has built in maven depency management and we in this version added
Ivy to help with this.Our ivy.xml file:
![img.png](img.png)

We needed to manually define a build.xml file to compile the project and run the app.

![img_2.png](img_2.png)

Resolve downloads the dependencies specified in ivy.xml and puts them in the right lib destination.
Compile takes the java files,converts them into jvm readable format(bytecode) and puts them in right folder.
The run server runs the main class with the arguments required knowing where to find the needed files because of the classpath.

*Running Tests*
This task compiles the files in the test folder to bytecode then uses the junitlauncher to run tests finding them with the fileset task.

![img_1.png](img_1.png)

*Backing up code*
Using the built it copy function to copy the files to a backup destination

![img_3.png](img_3.png)

*zipping the backup*
Using the zip function to zip the backup and send it to the backup location

![img_4.png](img_4.png)
# Part 2
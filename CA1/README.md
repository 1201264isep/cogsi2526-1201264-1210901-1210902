# cogsi2526-1210901-1210902
## CA1
### Self-evaluation
Hélder Rocha (1210901) - 50%\
Pedro Teixeira (1210902) - 50%

## Technical Report
testar conflitos 1

- ### Description of analysis
Analisamos os objetivos para a CA1 e percebemos que iria ser necessário utilizar vários comandos de git.

- ### Design
- ### Implementation
- 1 - Criamos o diretório CA1 (mkdir CA1) e copiamos o projeto spring-framework-petclinic para dentro do diretório CA1 (mv spring-framework-petclinic CA1/).
- 2 - Fizemos um git add . para adicionar todos os ficheiros ao stage.
- 3 - Fizemos um git commit -m "Setup CA1 project and initial Readme" para criar o primeiro commit.
- 4 - Fizemos push para o repositório remoto (git push origin).
- 5 - Criamos a primeira tag (git tag v1.1.0) e fizemos push da tag para o repositório remoto (git push origin v1.1.0).
- 6 - Criamos um novo atributo na classe Vet (private int professionalLicenseNumber) e o seu respetivo suporte.
- 7 - Foi necessário alterar alguns testes para garantir compatibilidade com este novo atributo.
- 8 - Utilizamos o comando git commit -am "Added and tested professional license number to vet" para criar um novo commit (este comando engloba o "git add ." e o "git commit -m ".."").
- 9 - Fizemos push do commit para o repositório remoto (git push origin).
- 10 - Criamos uma tag para este commit (git tag v1.2.0) e fizemos push da tag para o repositório remoto (git push origin v1.2.0).
- 11 - Utilizamos os comando git log com as opções --oneline e --graphgit.
- 12 - Testamos fazer revert para um commit anterior (git revert 6f293bc).
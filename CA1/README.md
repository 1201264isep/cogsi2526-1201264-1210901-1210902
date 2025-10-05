

# cogsi2526-1210901-1210902
## CA1
### Self-evaluation
Hélder Rocha (1210901) - 33,33%
Pedro Teixeira (1210902) - 33,33%
Francisco Gouveia(1201264) - 33,33%
## Technical Report

- ### Description of analysis
Analisamos os objetivos para a CA1 e percebemos que iria ser necessário utilizar vários comandos de git.

- ### Implementation
- 
#### Part 1
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

#### Part 2
- 13 - Criamos uma nova branch para desenvolvermos a feature pedida (git switch -C feature/email-field)
- 14 - Criamos um novo atributo na classe Vet (private int email) e o seu respetivo suporte.
- 15 - Foi necessário alterar alguns testes para garantir compatibilidade com este novo atributo.
- 16 - Utilizamos o comando git commit -am "Added email field to the Vet" para criar um novo commit (este comando engloba o "git add ." e o "git commit -m ".."").
- 17 - Demos push do commit para a nossa branch remota (git push origin feature/email-field).
- 18 - Fizemos checkout para a nossa branch main para podermos dar merge da nossa branch de desenvolvimento com main (git checkout main).
- 19 - Depois de estarmos na branch main fizemos o merge (git merge feature/email-field).
- 20 - O merge foi bem sucedido pois não haviam quaisquer conflitos.
- 21 - Depois do merge podemos verificar que o commit que estava na nossa branch de desenvolvimento agora se encontra em main.
- 22 - Criamos uma tag v1.3.0 em main com o nosso commit que continha as alterações. 
- 23 - De maneira a criar conflitos para se realizar um rebase, criei duas nova branch (git switch -C test_conflicts_1 e git switch -C test_conflicts_2) e alterei a linha 11 do readme em cada uma das branches.
- 24 - Repeti o que foi feito nos steps 16,17,18,19.
- 25 - Numa das branchs o merge correu bem como o anterior, mas na outra deparamo-nos com conflitos.
- 26 - Para resolver estes conflitos, fomos à branch main (git checkout main) e fizemos git pull de maneira a ficarmos com esta branch atualizada.
- 27 - Depois fomos para a nossa branch de desenvolvimento (git checkout test_conflicts_2) e fizemos um rebase com a branch main (git rebase main).
- 28 - Surgiram conflitos que foram tratados no código.
- 29 - Demos git add ao readme para atualizá-lo, de seguida fizemos git rebase --continue e verificamos que não haviam mais conflitos, tal como esperado.
- 30 - Depois repetimos os passos 18,19 e 20 que já correram como esperado pois o rebase já tinha sido realizado.

#### Alternativas
Duas alternativas para o git são o Mercurial e Apache Subversion(SVN)
###  Comparação
## Mercurial
O Mercurial tal como o Git é um sistema de controlo de versões distribuido permitindo que funcione localmente sem um servidor central. Este tem um foco na simplicidade tendo
a maior parte das features de versão de controlo(branching,merging,tagging) mas de forma mais simples de usar.
A maior diferença entre eles é o facto de o Mercurial por default não permitir alterar commits tirando o último.
## SVN
O SVN é sistema de controlo de versões centralizado,isto é, existe apenas um repositoŕio central online onde todos os developers trabalham requirindo conexão à internet para
qualquer operação. Devido a esta natureza centralizada o histórico do SVN é linear o que torna mais simples de entender estas alterações mas dificulta o desenvolvimento 
ao mesmo tempo por vários membros. O SVN permite merging mas de forma mais simples que o Git.
Em termo de branching o SVN funciona de forma que cada branch é uma cópia do diretório dentro do repositório enquanto no Git branches são apenas pointers para commits. 

### Implementação mercurial
## Parte 1
- 1 - Criamos o diretório mercurial e copiamos o spring-framework-petclinic para o diretório.
- 2 - Criamos um ficheiro hgignore para ignorar os build artefacts e usamos o hg config --edit para configurar um user
- 3 - Fizemos um hg add . para dar track aos ficheiros e fizemos hg commit para criar o primeiro commit.
# Repositório remoto
 Devido ao facto do bitbucket ter acabado o suporte para mercurial decidi simular um relatório "remoto" onde possa dar push.Para isso criei um novo folder(mkdir mercurial-remoto)
 e fiz git innit nele. Voltei ao diretório inicial(mercurial) e editei o .hg/hgrc file para adicionar o mercurial-remote como o origin.
- 4 - Adicionamos a tag (hg tag v1.1.0) e fizemos push para o repositório remoto (hg  push origin).
# Alterações
Tendo em conta que o âmbito desta implementação é o uso de uma nova versão de controlo o framework copiado foi o final, as alterações no projeto não serão as mesmas mas sim
ficheiros diferentes que façam o mesmo efeito.
- 6 - Foram alterados ficheiros.
- 8 - Utilizamos o comando hg commit para criar um novo commit,hg tag para adicionar a tag e hg push origin para fazer push para o repositório remoto.
- 9 - Utilizamos os comando hg log com a opção --graph.
- 10 - Testamos fazer revert dum ficheiro para o estado do primeiro commit (hg revert -r 0 spring-framework-petclinic/src/main/java/org/springframework/samples/petclinic/model/Pet.java).
- 11 - Vimos a diferença com hg diff  spring-framework-petclinic/src/main/java/org/springframework/samples/petclinic/model/Pet.java
- 12 - Voltamos ao estado do ultimo commit com hg update -r 4 e mostramos o branch com hg branch
- 13 - Marcamos o ultimo commit usando hg tag ca1-part1 -r 4
## Parte 2
- 14 - Criamos uma branch email-field para a nova feature (hg branch email-field)
- 15 - Fizemos alterações no ficheiro vet
- 16 - Damos commit neste novo branch e fazemos hg update default para voltarmos para o branch default.
- 17 - De seguida fazemos hg merge email-field para dar merge e damos commit no default branch
- 18 - Adicionamos a tag v1.3.0 e damos push para o remoto
- 19 - Criamos um branch com hg branch conflito e damos commit.(hg branch apenas aponta para o novo branch é preciso commit para ele ser criado)
- 20 - Alteramos os ficheiros de configuração .hg/hgrc para usar o nano como editor default
- 21 - Fizemos alterações  no ficheiro model/vets.java no branch default e demos commit
- 22 - Trocamos de branch com o hg branch conflito e hg update conflito para ir buscar o branch E alteramos o mesmo ficheiro vets com informação em conflito
- 23 - Fizemos commit neste branch conflito e trocamos para o default com hg update default e hg branch default 
- 24 - Aqui fizemos hg merge conflito e ouve merge conflicts que foram resolvidos no editor.
- 25 - Fizemos um commit do merge,adicionamos a tag e demos push para o remoto com hg push origin --new-branch visto que os branchs no mercurial são permanentes.

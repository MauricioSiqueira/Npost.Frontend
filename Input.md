Construa a tela de SignUp utilizando a imagem dentro da pasta assets nomeada como SignUp.png. 
Essa tela não deve possuir scrol.
Essa tela se refere ao botao Sign Up na tela de login. Ao clicar na setinha de backword da tela de Sign Up deve voltar para a tela de login e caso o usuario clicar em Login deve voltar também para tela de login. 
Os campos Email, Senha e Confirmar senha deve conter validações.
Para o email deve ser validado se é um email valido
para as senhas se elas são senhas complexas ( Ao menos uma letra Maiuscula, uma minuscula, um numero e um caractere especial)

Ao clicar no botao register ira consumir uma rota http://Localhost:6001/v1/usuario/create 
e enviará um json com um DTO de input para a criacao do usuario, Nesse dto deve conter Nome, Sobrenome, Email, Data de Nascimento, Celular, Senha e a Confirmacao da senha para o backend poder persistir esses dados, e o retorno será um status code que se for sucesso deve ser uma pagina com o layout parecido com esse, o que muda é que deve aparecer um circulo com uma seta de de check para dizer que a conta foi criada com sucesso e que será enviado um email de confirmacao de criacao de conta para o email que o usuario informou, nessa mensagem tem que conter o email que ele preencheu para ele saber qual email ele tem que olhar. e terá também um botão escrito voltar ao login que deverá direcionar o usuario para a tela de login. Caso o backend não retorne 200 - Status de sucesso deve aparecer uma mensagem vermelha abaixo do botao register informando que deu erro na criacao do usuario.y
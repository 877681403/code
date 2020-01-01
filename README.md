oracleSql
Liu.123456

ssh-keygen -t rsa -C "877681403@qq.com"
cat ~/.ssh/id_rsa.pub

…or create a new repository on the command line
echo "# code" >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin https://github.com/877681403/code.git
git push -u origin master
…or push an existing repository from the command line
git remote add origin https://github.com/877681403/code.git
git push -u origin master
…or import code from another repository
You can initialize this repository with code from a Subversion, Mercurial, or TFS project.

  git config --global user.email "877681403@qq.com"
  git config --global user.name "lxn"

git remote add origin git@github.com:877681403/code.git

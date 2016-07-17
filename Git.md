# Git Config & Manual

### Install & Consiguration
```
sudo pacman -S git
yaourt -S bcompare
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global core.editor vim
git config --global user.name "wangbx66"
git config --global user.email "wangbx66@gmail.com"
git config --global credential.helper store
```

### Remote Source Control
```
git remote -v
git remote show [remote]
git remote add [remote] [url/localpath]
git remote rm [remote]
```

### Pull & Push
```
git fetch [remote] [branch]
git diff master origin/master # check difference
git merge [remote]/[branch]
git checkout -b [branch] [remote]/[branch] # create, fetch, and merge remote branch
git pull (git fetch origin/master; git merge prigin/master)
git mergetool
git rm --cached [file] #remove from tree but keep in working dir
git rm \*~ #also remove from working dir, respect escape
git mv file_ori file
git diff #compares working dir and staging area
git diff --cached (git diff --staged) #show staged changes
git commit -a -m 'en' (git add -A; git commit -m 'en')
git push [remote] [branch]
```

### Branch
```
git fetch --all # fetch all branches
git branch -vv # show branches, upstreams, and status
git branch --merged # show obselete branches, --no-merged for active
git branch -d [branch] # delete
git branch -u [remote]/[branch] # set upstream
git push [remote] --delete [branch] # delete [remote]/[branch]
git remote show [remote] (git ls-remote [remote]) # show push/pull branch config
git push [remote] [branch] # push [branch] to [remote]/[branch]
git branch [branch] # creates local [branch]
git checkout -b [branch] # creates and switch to [branch]
git checkout -b [localbranch] [remote]/[branch] # clone, rename and switch
git checkout [branch] # clone if not exists, and switch
git merge [branch] # merge [branch] to current branch
```

### History & Undo
* Use with caution, undo is the only thing you cant undo
* [Source](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History) about history
```
git log # list recent commits, also list diff of last x commits if -p -2, also list #+- if --stat, limit it with --since=2.weeks
git log --pretty=format:"%h - %an, %ar : %s" #stands for hash, author, time, msg
git checkout -- file # revert file to last commit
git reset HEAD file # undo add file
git commit --amend # undo last commit and commit again
```

### Example - Merge Repos
```
git clone https://github.com/wangbx66/proj1
git clone https://github.com/wangbx66/proj2
proj2$ git remote add proj1 ../proj1
proj2$ git fetch proj1
proj2$ git merge proj1/master
```

### Example - Make A Change
```
git push [remote] --delete [branch]
git checkout -b [branch]
(working on local ...)
git pull [remote] master
git push [remote] [branch]
git checkout master
git merge [branch]
```

### Example - Return Everything
```
git reset HEAD --hard
git clean -fd
git pull
```

### Example - Submodule
```
git submodule add [remote]
git submodule init
(everytime to update submodule)
git pull --recurse-submodules
git submodule update --recursive
(to delelte a submodule)
git submodule deinit [submodule]
git rm [submodule]
```

### Example - See What's New on Remote
```
git diff master...origin/master
```

### Example - No Longer Track A File
```
echo "filename" >> .gitignore
git rm --cached filename
```

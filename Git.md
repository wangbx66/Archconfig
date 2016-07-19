# Git Config & Manual

### Install & Configuration
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

To list the remotes
```
git remote -v
git remote show [remote]
```
And to modify the remote list
```
git remote add [remote] [url]
git remote rm [remote]
```

### Pull & Push

To fetch the updates, inspect what's new, and merge it to the local repo,
```
git fetch [remote] [branch]
git diff master origin/master
git merge [remote]/[branch]
(conflict)$ git mergetool
```
Alternatively, do either for [branch]
```
git checkout -b [branch] [remote]/[branch]
```
Or for *master*
```
git pull
```
For mis-added or mis-named file, modify the tree using
```
git rm --cached [file]
git mv [file] [new]
```
To take differences introduced by *git add*, or by *git commit*, or between arbitrary commits such as *master* and *origin/master*, or one-side differences, use
```
git diff
git diff --cached
git diff [commit1] [commit2]
git diff [commit1]...[commit2]
```
To quickly synchronize the work to remote, use
```
git commit -a -m '[message]'
git push [remote] [branch]
```

### Branching

To fetch, list all branches, or show obselete or active branches
```
git fetch --all
git branch -vv
git branch --merged
git branch --no-merged
```
To delete a local or remote branch
```
git branch -d [branch]
git push [remote] --delete [branch]
```
To list all branches on *remote*
```
git remote show [remote] (git ls-remote [remote])
```
To create a local branch and switch to that, or clone a remote branch and switch to that,
```
git checkout -b [branch]
git checkout [branch]
```
Finally to merge *branch* into current branch, which usually happens on *master*
```
git merge [branch]
```

### History & Undo

* **Use with caution! Undo is the only thing you can not undo**
* [Source](https://git-scm.com/book/en/v2/Git-Basics-Viewing-the-Commit-History) about history

To, for example, checkout the workload of last 2 weeks, where *h*, *an*, *ar* and *s* are standing for hast, author, time and message, respectively
```
git log --stat --since=2.weeks --pretty=format:"%h - %an, %ar : %s"
```
To revert a file to last commit
```
git checkout -- file
```
To undo adding a file
```
git reset HEAD file
```
To undo last commit
```
git commit --amend
```

### Submodule

Add a submodule using
```
git submodule add [remote]
git submodule init
```
And for everytime to update submodule
```
git pull --recurse-submodules
git submodule update --recursive
```
To delelte a submodule
```
git submodule deinit [submodule]
git rm [submodule]
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
# working on local ...
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

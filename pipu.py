import pip
import subprocess

def source(project):
    if project.lower() == 'theano':
        return 'git+https://github.com/Theano/Theano.git'
    elif project.lower() == 'lasagne':
        return 'git+https://github.com/Lasagne/Lasagne.git'
    elif project.lower() == 'pip':
        return 'null'
    else:
        return project

for dist in pip.get_installed_distributions():
    subprocess.run('pip install --upgrade --user {0}'.format(source(dist.project_name)), shell=True)

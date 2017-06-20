---
layout: home
---

We use Couscous generates a [GitHub pages](http://pages.github.com/) website from your markdown documentation.

# Contribution Guide

1. Add new documentation markdown files to the root directory
2. Images path will be to the root of the website (/images/<yourimage.png>)
3. All files names should be lowercase and no spaces
4. Image file names should be .png and **NOT** .PNG


## Steps to run Couscous on Windows 10

### 1. Install bash on Windows 10
[Bash on Windows article](http://www.windowscentral.com/how-install-bash-shell-command-line-windows-10)

### 2. Get couscous working on bash shell
[Getting Started](http://couscous.io/docs/getting-started.html)

### 3. Install PHP7x using Bash on Windows

1. Install Pre-requisites > On bash prompt

    ```bash
    sudo apt-get install build-essential libxml2-dev
    ```



2. Install php5
    ```bash
    sudo apt-get install php
    ```


3. Get php package and install

    ```bash
    wget http://php.net/get/php-7.1.5.tar.bz2/from/this/mirror -O php-7.1.5.tar.bz2
    sudo apt install make
    tar -xvf php-7.1.5.tar.bz2
    cd php-7.1.5
    ./configure
    make
    make test # Neither mandatory nor a bad idea.
    sudo make install
    ```
    
4. Install NPM and bower
	```bash
    sudo apt-get install composer
	
	sudo apt-get install npm 
	sudo npm install -g bower
	
	sudo npm install -g less less-plugin-clean-css
    ```

	if the npm install fails, then likely the nodejs is not syslinked to node. Run the following command to fix it
	
    ```bash
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    ```

### 4. Run couscous from the bash window

You might have to Change directory  mount the folder to the
	
```bash
cd /mnt/c/<path_to_docs_cloudneeti>
couscous preview
```

Verify your changes on the browser. Most likely the URL would be http://127.0.0.1:8000/deployment-guide.html


### 4. Deploy to gh_pages

The following command will push the generated files to gh_pages branch

```bash
couscous deploy
```

	


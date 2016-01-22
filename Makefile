## system specific commands
SUDO			:= sudo
MKDIR			:= mkdir --parents
LINK			:= ln --symbolic --force
TOUCH			:= touch

CODE_DIR		:= $(HOME)/code
MODULE_DIR		:= $(HOME)/.modules
INSTALL_PACKAGE_FLAGS	:= --yes --force-yes
INSTALL_PACKAGE_CMD	:= apt-get install $(INSTALL_PACKAGE_FLAGS)

ADD_REPO_FLAGS		:= --yes
ADD_REPO_CMD		:= $(SUDO) apt-add-repository $(ADD_REPO_FLAGS)
UPDATE_REPO_CACHE_CMD	:= $(SUDO) apt-get update -qq

RUBY_VERSION		:= 2.2.2
EMACS_VERSION		:= 24.5
EMACS			:= emacs-$(EMACS_VERSION)

define touch-module
	$(MKDIR) $(MODULE_DIR) && $(TOUCH) $(MODULE_DIR)/$@
endef

REQUIRED_MODULES = \
	bash-completion	\
	code		\
	emacs		\
	git		\
	langtool 	\
	postgresql	\
	repositories	\
	ruby

OPTIONAL_MODULES = \
	cask 		\
	cedilla		\
	dconf		\
	desktop		\
	docker		\
	firacode	\
	mimipass	\
	reditr		\
	slack		\
	source-code-pro

LANGUAGES = \
	clojure		\
	elixir		\
	haskell		\
	octave		\
	scala		\
	smlnj

define add-repositories
	echo $(REPOSITORIES) | xargs -n 1 $(ADD_REPO_CMD)
	$(UPDATE_REPO_CACHE_CMD)
endef

REPOSITORIES = \
	ppa:brightbox/ruby-ng		\
	ppa:cassou/emacs		\
	ppa:chris-lea/node.js		\
	ppa:git-core/ppa		\
	ppa:paolorotolo/copy		\
	ppa:webupd8team/java		\
	ppa:pi-rho/dev

define install-packages
	$(SUDO) $(INSTALL_PACKAGE_CMD) $(PACKAGES)
endef

PACKAGES = \
	aspell-pt-br			\
	bash-completion			\
	bashdb				\
	bitlbee				\
	build-essential			\
	copy 				\
	curl				\
	dnsutils			\
	ftp				\
	g++-multilib			\
	gcc-multilib			\
	git				\
	gnupg				\
	gnupg-agent			\
	guile-2.0-dev			\
	html2text			\
	libcurl3			\
	libcurl4-openssl-dev		\
	libgmime-2.6-dev		\
	libnspr4-0d			\
	libqt4-opengl			\
	libreadline6			\
	libreadline6-dev		\
	libsqlite3-dev			\
	libssl-dev			\
	libwebkit-dev			\
	libxapian-dev			\
	libxss1				\
	lxde				\
	markdown			\
	maven				\
	mongodb-org			\
	ncftp				\
	network-manager-openvpn		\
	openjdk-7-jdk			\
	openssh-server			\
	python-software-properties	\
	redis-server 			\
	ruby2.1				\
	ruby2.1-dev			\
	samba				\
	silversearcher-ag		\
	socat				\
	ssh				\
	surfraw				\
	telnet				\
	texlive				\
	tmux				\
	tree				\
	ttf-ancient-fonts		\
	units				\
	w3m				\
	wget				\
	wl				\
	wordnet				\
	xclip				\
	xdg-utils

###
# It all begins here
install: $(REQUIRED_MODULES)
optional: $(OPTIONAL_MODULES)
languages: $(LANGUAGES)
all: install optional languages

clean:
	rm -rf $(MODULE_DIR)

%: $(MODULE_DIR)/%
	if [ ! -f $(MODULE_DIR)/$@ ]; then $(touch-module); fi

###
# Add external repositories for packages
$(MODULE_DIR)/repositories: | mongodb-repo
	$(add-repositories)

$(MODULE_DIR)/mongodb-repo:
	echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | $(SUDO) tee /etc/apt/sources.list.d/mongodb.list
	$(SUDO) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10

$(MODULE_DIR)/spotify-repo:
	$(SUDO) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 94558F59
	$(SUDO) su -c "echo 'deb http://repository.spotify.com stable non-free' > /etc/apt/sources.list.d/spotify.list"

###
# Install packages
$(MODULE_DIR)/packages: | repositories
	$(install-packages)

###
# Install programming stuff
$(MODULE_DIR)/git: | packages
	$(CODE_DIR)/linuxsetup/scripts/setup_git

$(MODULE_DIR)/mimipass: | git
	$(MKDIR) $(CODE_DIR)
	git -C $(CODE_DIR) clone 'git@github.com:rranelli/mimipass.git'
	$(CODE_DIR)/mimipass/link-mimipass

$(MODULE_DIR)/code: | packages
	$(MKDIR) $(CODE_DIR)
	$(CODE_DIR)/linuxsetup/scripts/gitmulticast.sh

$(MODULE_DIR)/ruby: | packages
	git clone https://github.com/sstephenson/rbenv.git $(HOME)/.rbenv --depth=1
	git clone https://github.com/sstephenson/ruby-build.git $(HOME)/.rbenv/plugins/ruby-build --depth=1

	$(HOME)/.rbenv/bin/rbenv install $(RUBY_VERSION)
	$(HOME)/.rbenv/bin/rbenv global $(RUBY_VERSION)
	$(HOME)/.rbenv/bin/rbenv rehash

$(MODULE_DIR)/clojure: | packages
	$(MKDIR) $(HOME)/.lein
	wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
	mv -f lein ~/.lein/; chmod 755 ~/.lein/lein

$(MODULE_DIR)/java8: PACKAGES = oracle-java8-installer
$(MODULE_DIR)/java8: | packages
	$(install-packages)

$(MODULE_DIR)/smlnj: | packages
	wget 'http://smlnj.org/dist/working/110.74/config.tgz'
	$(MKDIR) $(HOME)/.sml
	mv config.tgz $(HOME)/.sml
	cd $(HOME)/.sml && \
		tar -xvf config.tgz && \
		config/install.sh && \
		rm -rf config.tgz config/

$(MODULE_DIR)/nodejs: PACKAGES = nodejs
$(MODULE_DIR)/nodejs:
	curl -sL https://deb.nodesource.com/setup_5.x | sudo -E bash -
	$(install-packages)

$(MODULE_DIR)/scala: PACKAGES = sbt
$(MODULE_DIR)/scala: | packages
	echo "deb http://dl.bintray.com/sbt/debian /" | $(SUDO) tee -a /etc/apt/sources.list.d/sbt.list
	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

	$(MKDIR) $(HOME)/.sbt/0.13/plugins
	echo 'addSbtPlugin ("org.ensime" % "ensime-sbt" % "0.1.6")' > $(HOME)/.sbt/0.13/plugins/plugins.sbt

$(MODULE_DIR)/elixir: PACKAGES = erlang
$(MODULE_DIR)/elixir: | code
	$(SUDO) su -c "echo 'deb http://packages.erlang-solutions.com/ubuntu trusty contrib' > /etc/apt/sources.list.d/esl-erlang.list"
	wget http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc
	$(SUDO) apt-key add erlang_solutions.asc
	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

	cd $(HOME)/code/elixir && make clean test

$(MODULE_DIR)/haskell: TARFILE := haskell-platform-2014.2.0.0-unknown-linux-x86_64.tar.gz
$(MODULE_DIR)/haskell: TARPATH := $(CURDIR)/$(TARFILE)
$(MODULE_DIR)/haskell: | packages
	wget https://www.haskell.org/platform/download/2014.2.0.0/$(TARFILE)
	cd / && $(SUDO) tar xvf $(TARPATH)
	$(SUDO) /usr/local/haskell/ghc-7.8.3-x86_64/bin/activate-hs
	rm $(TARPATH)

$(MODULE_DIR)/octave: PACKAGES = octave
$(MODULE_DIR)/octave:
	$(install-packages)

$(MODULE_DIR)/bash-completion: | packages
	$(SUDO) su -c "echo 'set completion-ignore-case on' >> /etc/inputrc"
	$(SUDO) cp -f bash_completion.d/* /etc/bash_completion.d/

editor: emacs
$(MODULE_DIR)/emacs: | packages code
	wget http://ftpmirror.gnu.org/emacs/$(EMACS).tar.xz
	tar -xvf $(EMACS).tar.xz

	$(SUDO) apt-get build-dep emacs24 -y

	cd $(EMACS) && ./configure --with-x-toolkit=lucid
	make -C $(EMACS)/
	$(SUDO) make -C $(EMACS)/ install

	rm -rf $(EMACS)*

	$(CODE_DIR)/emacs-dotfiles/setup_dotfiles

$(MODULE_DIR)/cask: | packages
	curl -fsSL https://raw.githubusercontent.com/cask/cask/master/go | python

$(MODULE_DIR)/langtool: LANGTOOL=LanguageTool-2.8
$(MODULE_DIR)/langtool: LANGTOOL_ZIP_URL=https://languagetool.org/download/$(LANGTOOL).zip
$(MODULE_DIR)/langtool: | packages
	wget $(LANGTOOL_ZIP_URL)
	unzip $(LANGTOOL)
	mv $(LANGTOOL)/ $(HOME)/.langtool
	rm $(LANGTOOL).zip

###
# Install desktop stuff
$(MODULE_DIR)/desktop: PACKAGES = \
		calibre				\
		dconf-tools			\
		deluge				\
		deluge-console			\
		deluged				\
		elementary-.*-theme		\
		elementary-tweaks		\
		elementary-wallpapers-extra	\
		firefox				\
		flashplugin-installer		\
		icedtea-7-plugin		\
		pidgin				\
		remmina				\
		spotify-client			\
		telegram
$(MODULE_DIR)/desktop: REPOSITORIES = \
		ppa:atareao/telegram			\
		ppa:elementary-os/unstable-upstream	\
		ppa:mpstark/elementary-tweaks-daily	\
		ppa:pidgin-developers/ppa
$(MODULE_DIR)/desktop: | install spotify-repo
	cd $(CODE_DIR)/emacs-dotfiles && $(SUDO) ./setup_shortcut

# fixes pantheon terminal C-d issue.
# see https://bugs.launchpad.net/pantheon-terminal/+bug/1364704
	gsettings set org.pantheon.terminal.settings save-exited-tabs false

	$(add-repositories)
	$(install-packages)

$(MODULE_DIR)/keysnail: | desktop
	wget https://github.com/mooz/keysnail/raw/master/keysnail.xpi
	firefox keysnail.xpi

$(MODULE_DIR)/postgresql: PACKAGES = postgresql-9.4 libpq-dev
$(MODULE_DIR)/postgresql: | packages
	echo 'deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main' \
	  | $(SUDO) tee /etc/apt/sources.list.d/postgresql.list
	wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
	  | $(SUDO) apt-key add -

	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

	$(SUDO) $(LINK) $(CURDIR)/scripts/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.conf
	$(SUDO) service postgresql restart

$(MODULE_DIR)/docker: PACKAGES = lxc-docker
$(MODULE_DIR)/docker: | packages
	$(SUDO) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys
	$(SUDO) sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

	$(SUDO) usermod -a -G docker $(USER) # adding current user to docker group
	$(SUDO) service docker restart

$(MODULE_DIR)/vagrant: | packages virtualbox
	wget https://dl.bintray.com/mitchellh/vagrant/vagrant_1.7.2_x86_64.deb
	$(SUDO) dpkg -i vagrant_1.7.2_x86_64.deb
	rm vagrant_*.deb

$(MODULE_DIR)/virtualbox: | packages
	wget http://download.virtualbox.org/virtualbox/4.3.24/virtualbox-4.3_4.3.24-98716~Ubuntu~precise_amd64.deb
	$(SUDO) dpkg -i virtualbox-4.3_4.3.24-98716~Ubuntu~precise_amd64.deb
	rm virtualbox-*.deb

$(MODULE_DIR)/slack: | packages
	wget https://slack-ssb-updates.global.ssl.fastly.net/linux_releases/slack-desktop-1.2.6-amd64.deb
	$(SUDO) dpkg -i slack*.deb
	rm slack*.deb

$(MODULE_DIR)/source-code-pro:
	wget https://github.com/adobe-fonts/source-code-pro/archive/1.017R.zip
	unzip 1.017R.zip
	$(MKDIR) -p ~/.fonts
	cp source-code-pro-1.017R/OTF/*.otf ~/.fonts/
	fc-cache -f -v
	rm -rf source-code-pro-1.017R/ 1.017R.zip

$(MODULE_DIR)/firacode:
	wget https://github.com/tonsky/FiraCode/releases/download/1.101/FiraCode_1.101.zip
	unzip FiraCode*.zip
	$(MKDIR) -p ~/.fonts
	cp FiraCode*/*.otf ~/.fonts
	fc-cache -f -v
	rm -rf FiraCode*/ FiraCode*.zip

$(MODULE_DIR)/cedilla:
	$(SUDO) su -c "echo 'GTK_IM_MODULE=cedilla' >> /etc/environment"
	$(SUDO) su -c "echo 'QT_IM_MODULE=cedilla' >> /etc/environment"
	$(SUDO) cp /usr/share/X11/locale/en_US.UTF-8/Compose /usr/share/X11/locale/en_US.UTF-8/Compose.bak
	$(SUDO) sed -e 's/ć/ç/g' -e 's/Ć/Ç/g' -i /usr/share/X11/locale/en_US.UTF-8/Compose

$(MODULE_DIR)/dconf:
	gsettings set org.gnome.mutter workspaces-only-on-primary false
	gsettings set org.pantheon.terminal.settings alt-changes-tab false
	gsettings set org.pantheon.terminal.settings tab-bar-behavior 'Hide When Single Tab'
	gsettings set org.gnome.crypto.cache gpg-cache-method 'timeout'
	gsettings set org.gnome.crypto.cache gpg-cache-ttl 3600

$(MODULE_DIR)/reditr:
	wget https://launchpad.net/ubuntu/+source/udev/175-0ubuntu19/+build/4325788/+files/libudev0_175-0ubuntu19_amd64.deb
	$(SUDO) dpkg -i libudev0_175-0ubuntu19_amd64.deb
	rm libudev0_175-0ubuntu19_amd64.deb

	wget http://reditr.com/downloads/linux/reditr_amd64.deb
	$(SUDO) dpkg -i reditr_amd64.deb
	rm reditr_amd64.deb

$(MODULE_DIR)/conkeror:
$(MODULE_DIR)/conkeror: | packages
	echo 'deb http://noone.org/conkeror-nightly-debs jessie main' \
	  | $(SUDO) tee /etc/apt/sources.list.d/conkeror.list
	echo 'deb-src http://noone.org/conkeror-nightly-debs jessie main' \
	  | $(SUDO) tee -a /etc/apt/sources.list.d/conkeror.list

	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

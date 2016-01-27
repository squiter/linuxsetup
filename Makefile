## system specific commands
SUDO			:= sudo
MKDIR			:= mkdir --parents
LINK			:= ln --symbolic --force
TOUCH			:= touch

CODE_DIR		:= $(HOME)/projetos
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
	emacs		\
	git		\
	langtool	\
	ruby

OPTIONAL_MODULES = \
	cask 		\
	dconf		\
	desktop		\
	docker		\
	slack		\
	source-code-pro

define add-repositories
	echo $(REPOSITORIES) | xargs -n 1 $(ADD_REPO_CMD)
	$(UPDATE_REPO_CACHE_CMD)
endef

REPOSITORIES = \
	ppa:brightbox/ruby-ng		\
	ppa:cassou/emacs		\
	ppa:git-core/ppa		\
	ppa:pi-rho/dev

define install-packages
	$(SUDO) $(INSTALL_PACKAGE_CMD) $(PACKAGES)
endef

PACKAGES = \
	aspell-pt-br			\
	bash-completion			\
	build-essential			\
	curl				\
	dnsutils			\
	ftp				\
	git				\
	gnupg				\
	gnupg-agent			\
	libreadline-dev			\
	libssl-dev			\
	ruby2.1				\
	ruby2.1-dev			\
	samba				\
	silversearcher-ag		\
	ssh				\
	telnet				\
	tmux				\
	tree				\
	wget				\
	xclip

###
# It all begins here
install: $(REQUIRED_MODULES)
optional: $(OPTIONAL_MODULES)
all: install optional

clean:
	rm -rf $(MODULE_DIR)

%: $(MODULE_DIR)/%
	if [ ! -f $(MODULE_DIR)/$@ ]; then $(touch-module); fi

###
# Add external repositories for packages
$(MODULE_DIR)/spotify-repo:
	$(SUDO) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 94558F59
	$(SUDO) su -c "echo 'deb http://repository.spotify.com stable non-free' > /etc/apt/sources.list.d/spotify.list"

###
# Install packages
$(MODULE_DIR)/packages:
	$(install-packages)

###
# Install programming stuff
$(MODULE_DIR)/git: | packages
	$(CODE_DIR)/linuxsetup/scripts/setup_git

$(MODULE_DIR)/ruby: | packages
	if [ ! -d $(HOME)/.rbenv ]; then git clone https://github.com/sstephenson/rbenv.git $(HOME)/.rbenv --depth=1; fi
	if [ ! -d $(HOME)/.rbenv ]; then git clone https://github.com/sstephenson/ruby-build.git $(HOME)/.rbenv/plugins/ruby-build --depth=1; fi

	$(HOME)/.rbenv/bin/rbenv install $(RUBY_VERSION)
	$(HOME)/.rbenv/bin/rbenv global $(RUBY_VERSION)
	$(HOME)/.rbenv/bin/rbenv rehash

$(MODULE_DIR)/bash-completion: | packages
	$(SUDO) su -c "echo 'set completion-ignore-case on' >> /etc/inputrc"
	$(SUDO) cp -f bash_completion.d/* /etc/bash_completion.d/

editor: emacs
$(MODULE_DIR)/emacs: | packages
	wget http://ftpmirror.gnu.org/emacs/$(EMACS).tar.xz
	tar -xvf $(EMACS).tar.xz

	$(SUDO) apt-get build-dep emacs24 -y

	cd $(EMACS) && ./configure --with-x-toolkit=lucid
	make -C $(EMACS)/
	$(SUDO) make -C $(EMACS)/ install

	rm -rf $(EMACS)*

# Setup emacs-dotfiles?

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
		firefox				\
		pidgin				\
		spotify-client			\
		telegram
$(MODULE_DIR)/desktop: REPOSITORIES = \
		ppa:atareao/telegram			\
		ppa:pidgin-developers/ppa
$(MODULE_DIR)/desktop: | install spotify-repo
	cd $(CODE_DIR)/emacs-dotfiles && $(SUDO) ./setup_shortcut

$(MODULE_DIR)/keysnail: | desktop
	wget https://github.com/mooz/keysnail/raw/master/keysnail.xpi
	firefox keysnail.xpi

$(MODULE_DIR)/docker: PACKAGES = lxc-docker
$(MODULE_DIR)/docker: | packages
	$(SUDO) apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys
	$(SUDO) sh -c "echo deb https://get.docker.com/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

	$(SUDO) usermod -a -G docker $(USER) # adding current user to docker group
	$(SUDO) service docker restart

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

$(MODULE_DIR)/conkeror:
$(MODULE_DIR)/conkeror: | packages
	echo 'deb http://noone.org/conkeror-nightly-debs jessie main' \
	  | $(SUDO) tee /etc/apt/sources.list.d/conkeror.list
	echo 'deb-src http://noone.org/conkeror-nightly-debs jessie main' \
	  | $(SUDO) tee -a /etc/apt/sources.list.d/conkeror.list

	$(UPDATE_REPO_CACHE_CMD)
	$(install-packages)

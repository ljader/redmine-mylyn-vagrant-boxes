#!/bin/sh

# Check the received options in order to set up some variables
PREFER_PACKAGE=1
while getopts ":g" opt; do
  case $opt in
    g)
      echo "==== [debug] Using the gem installer"
      PREFER_PACKAGE=0
      ;;
    \?)
      echo "==== [debug] Invalid option: -$OPTARG" >&2
      ;;
  esac
done

PATH=$PATH:/usr/local/bin/

# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/etc/puppet/

$(which git > /dev/null 2>&1)
FOUND_GIT=$?
$(which librarian-puppet > /dev/null 2>&1)
FOUND_LP=$?
$(which apt-get > /dev/null 2>&1)
FOUND_APT=$?
$(which yum > /dev/null 2>&1)
FOUND_YUM=$?
$(which puppet > /dev/null 2>&1)
FOUND_PUPPET=$?

InstallLibrarianPuppetGem () {
  RUBY_VERSION=$(ruby -e 'print RUBY_VERSION')
  echo "==== [debug] Attempting to install librarian-puppet gem. (ruby version $RUBY_VERSION)"
  case "$RUBY_VERSION" in
    1.8.*)
      # For ruby 1.8.x librarian-puppet needs to use 'highline' 1.6.x
      # highline >= 1.7.0 requires ruby >= 1.9.3
      gem install --no-ri --no-rdoc highline --version "~>1.6.0" > /dev/null 2>&1
      # Install the most recent 1.x.x version, but not 2.x.x which needs Ruby 1.9
      gem install --no-ri --no-rdoc librarian-puppet --version "~>1"
      ;;
    *)
      gem install --no-ri --no-rdoc librarian-puppet
      ;;
  esac
  echo '==== [debug] Librarian-puppet gem installed.'
}

if [ "${FOUND_YUM}" -eq '0' ]; then

  # Make sure Git is installed
  if [ "$FOUND_GIT" -ne '0' ]; then
    echo '==== [debug] Attempting to install Git.'
    yum -q -y makecache
    yum -q -y install git
    echo '==== [debug] Git installed.'
  fi

  # Make sure librarian-puppet is installed
  if [ "$FOUND_LP" -ne '0' ]; then
    InstallLibrarianPuppetGem
  fi

elif [ "${FOUND_APT}" -eq '0' ]; then

  apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 561F9B9CAC40B2F7
  apt-add-repository ppa:brightbox/ruby-ng


  apt-get -q -y update

  # TODO check ruby version and install if nessesary?

  # Make sure Puppet is installed
  if [ "$FOUND_PUPPET" -ne '0' ]; then
    echo '==== [debug] Attempting to install Puppet.'
    apt-get -q -y install puppet
    echo '==== [debug] Puppet installed.'
  fi

  # Make sure Git is installed
  if [ "$FOUND_GIT" -ne '0' ]; then
    echo '==== [debug] Attempting to install Git.'
    apt-get -q -y install git
    echo '==== [debug] Git installed.'
  fi

  # Make sure librarian-puppet is installed
  if [ "$FOUND_LP" -ne '0' ]; then
    if [ "$PREFER_PACKAGE" -eq 1 -a -n "$(apt-cache search librarian-puppet)" ]; then
       apt-get -q -y install librarian-puppet
       echo '==== [debug] Librarian-puppet installed from package'
    else
      dpkg -s ruby-json >/dev/null 2>&1
      if [ $? -ne 0 -a -n "$(apt-cache search ruby-json)" ]; then
        # Try and install json dependency from package if possible
        apt-get -q -y install ruby-json
      else
        echo '==== [debug] The ruby_json package was not installed (maybe, it was present). Attempting to install librarian-puppet anyway.'
      fi

      if [ -n "$(apt-cache search ruby2.1-dev)" ]; then
		apt-get -q -y install build-essential ruby2.1 ruby2.1-dev libruby2.1
      fi

      InstallLibrarianPuppetGem
    fi
  fi

else
  echo '==== [debug] No supported package installer available. You may need to install git and librarian-puppet manually.'
fi

if [ ! -d "$PUPPET_DIR" ]; then
  mkdir -p $PUPPET_DIR
fi
cp /vagrant/puppet/Puppetfile $PUPPET_DIR

cd $PUPPET_DIR && librarian-puppet install

echo '==== [debug] librarian-puppet setup finished'

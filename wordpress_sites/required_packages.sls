wordpress_install_required_packages:
    pkg.installed:
        - pkgs:
            - php5-mysql
            - postfix
            - wget
            - curl

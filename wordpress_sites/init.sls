{% from "wordpress_sites/map.jinja" import wordpress_sites with context %}

{% for site, args in wordpress_sites.sites.items() %}

# WordPress Files
{{ wordpress_sites.sites_base_dir }}/{{ site }}:
    archive.extracted:
        - source: "{{ wordpress_sites.wordpress_source }}"
        - source_hash: "{{ wordpress_sites.wordpress_source_hash }}"
        - archive_format: tar
        - tar_options: zxvf
        - user: "{{ args['user'] }}"
        - group: "{{ args['group'] }}"
        - if_missing: "{{ wordpress_sites.sites_base_dir }}/{{ site }}/wordpress"

# Theme File
wordpress_sites_{{ site }}_copy_theme:
    archive.extracted:
        - name: "{{ wordpress_sites.sites_base_dir }}/{{ site }}/wordpress/wp-content/themes/{{ args['theme_name'] }}/"
        - source: "{{ args["theme_source"] }}"
        - archive_format: tar
        - tar_options: zxvf
        - user: "{{ args['user'] }}"
        - group: "{{ args['group'] }}"

# WordPress Config
{{ wordpress_sites.sites_base_dir }}/{{ site }}/wordpress/wp-config.php:
    file.managed:
        - template: jinja
        - source: salt://wordpress_sites/files/wp-config.php.jinja
        - user: "{{ args['user'] }}"
        - group: "{{ args['group'] }}"
        - context:
            db_name: {{ args['db_name'] }}
            db_user: {{ args['db_user'] }}
            db_pass: {{ args['db_pass'] }}
            db_host: {{ args['db_host'] }}
            site: {{ site }}

# Database Setup
wordpress_sites_{{ site }}_mysql_db:
    mysql_database.present:
        - connection_user: "{{ wordpress_sites.db_connection_user }}"
        - connection_pass: "{{ wordpress_sites.db_connection_user_pass }}"
        - connection_charset: utf8
        - name: '{{ args["db_name"] }}'
wordpress_sites_{{ site }}_mysql_db_user:
    mysql_user.present:
        - connection_user: "{{ wordpress_sites.db_connection_user }}"
        - connection_pass: "{{ wordpress_sites.db_connection_user_pass }}"
        - connection_charset: utf8
        - name: "{{ args['db_user'] }}"
        - password: "{{ args['db_pass'] }}"
        - host: "{{ args['db_host'] }}"

#NGINX Site Config
/etc/nginx/sites-available/{{ args['site_domain'] }}.conf:
    file.managed:
        - template: jinja
        - source: salt://wordpress_sites/files/nginx-site.conf.jinja
        - context:
            server_name: {{ args['site_domain'] }}
            site_root: {{ wordpress_sites.sites_base_dir }}/{{ site }}/wordpress
            {% if 'https' in args %}
            https_enabled: True
            ssl_cert_path: /etc/ssl/{{ args['site_domain'] }}/ssl_cert.crt
            ssl_key_path: /etc/ssl/{{ args['site_domain'] }}/ssl_key.key
            {% else %}
            https_enabled: False
            {% endif %}



        - watch_in:
            - service: nginx
/etc/nginx/sites-enabled/{{ args['site_domain'] }}.conf:
    file.symlink:
        - target: /etc/nginx/sites-available/{{ args['site_domain'] }}.conf

{% if 'https' in args %}
# SSL Config
/etc/ssl/{{ args['site_domain'] }}/ssl_cert.crt:
    file.managed:
        - template: jinja
        - source: salt://wordpress_sites/files/ssl/cert.jinja
        - user: root
        - group: root
        - mode: 600
        - makedirs: True
        - context:
            site: {{ site }}

/etc/ssl/{{ args['site_domain'] }}/ssl_key.key:
    file.managed:
        - template: jinja
        - source: salt://wordpress_sites/files/ssl/key.jinja
        - user: root
        - group: root
        - mode: 600
        - makedirs: True
        - context:
            site: {{ site }}

{% endif %}

{% endfor %}

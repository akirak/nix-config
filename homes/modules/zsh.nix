{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    zsh
    nix-zsh-completions
    fzy
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    dotDir = "${config.xdg.configHome}/zsh";
    defaultKeymap = "emacs";
    history = {
      expireDuplicatesFirst = true;
      save = 5000;
      share = true;
      size = 5000;
    };

    plugins = [
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
      }
      {
        name = "fzy";
        src = pkgs.customZshPlugins.zsh-fzy;
      }
      {
        name = "nix-shell";
        src = pkgs.customZshPlugins.zsh-nix-shell;
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.customZshPlugins.zsh-fast-syntax-highlighting;
      }
      {
        name = "history-filter";
        src = pkgs.customZshPlugins.zsh-history-filter;
      }
    ];

    sessionVariables = {
      "DIRSTACKSIZE" = "20";
      "NIX_BUILD_SHELL" = "zsh";
      # "VAGRANT_WSL_WINDOWS_ACCESS" = "1";
      # Set locale archives
      # https://github.com/NixOS/nixpkgs/issues/38991
      "LOCALE_ARCHIVE_2_11" = "${pkgs.glibcLocales}/lib/locale/locale-archive";
      "LOCALE_ARCHIVE_2_27" = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    };

    initContent = ''
      setopt auto_cd
      setopt cdable_vars
      setopt auto_name_dirs
      setopt auto_pushd
      setopt pushd_ignore_dups
      setopt pushdminus

      # Configuration for zsh-fzy plugin https://github.com/aperezdc/zsh-fzy
      bindkey '\eq' fzy-proc-widget
      bindkey '\ew' fzy-cd-widget
      bindkey '\ee' fzy-file-widget
      bindkey '\er' fzy-history-widget
      zstyle :fzy:file command fd -t f
      zstyle :fzy:cd command fd -t d

      # Support directory tracking on emacs-libvterm.
      # https://github.com/akermu/emacs-libvterm#directory-tracking
      function chpwd() {
          print -Pn "\e]51;A$(pwd)\e\\";
      }

      function pick() {
        local arg
        fzy | read -r arg && "$@" "$arg"
      }

      function mountpoints() {
        findmnt -oTARGET --list --noheadings
      }

      function remotes() {
        git rev-parse --show-toplevel >/dev/null || return 1
        git --no-pager config --local --list \
          | sed -n -E 's/^remote\..+?\.url=(.+)/\1/p' \
          | xargs realpath -q -s -e
      }

      function projects() {
        {
          tmp=$(mktemp -p "''${XDG_RUNTIME_DIR}")
          trap "rm -f '$tmp'" ERR EXIT
          # If the server isn't running, this script will exit with 1.
          emacsclient --eval "(with-temp-buffer
             (insert (string-join
                      (thread-last
                        (project-known-project-roots)
                        (append (thread-last
                                  (frame-list)
                                  (mapcan #'window-list)
                                  (mapcar #'window-buffer)
                                  (mapcar (lambda (buffer)
                                            (buffer-local-value 'default-directory buffer)))))
                        (mapcar #'expand-file-name)
                        (seq-uniq))
                      \"\\n\"))
             (write-region (point-min) (point-max) \"$tmp\"))" > /dev/null
          cat "$tmp"
        }
      }

      function project-subdirectories() {
        local root="$(git rev-parse --show-toplevel)"
        if [[ -z "$root" ]]; then
          return 1
        else
          ( cd "$root" && fd -a -L -t d )
        fi
      }

      function emacs-visible-directories() {
          tmp=$(mktemp -p "''${XDG_RUNTIME_DIR}")
          trap "rm -f '$tmp'" ERR EXIT
          # If the server isn't running, this script will exit with 1.
          emacsclient --eval "(with-temp-buffer
             (insert (string-join
                        (thread-last
                          (window-list)
                          (mapcar #'window-buffer)
                          (mapcar (lambda (buffer)
                                    (expand-file-name
                                     (buffer-local-value 'default-directory buffer))))
                          (seq-uniq))
                      \"\\n\"))
             (write-region (point-min) (point-max) \"$tmp\"))" > /dev/null
          cat "$tmp"
      }

      function cdv() {
        builtin cd "$1" && pwd
      }

      function cd() {
        case "$1" in
          -h)
            echo <<-HELP
              Usage: cd [-p|-m|-r|DIR]

              Options:
                -p: Select an Emacs project (requires an Emacs server running)
                -m: Select a mount point
                -r: Select a remote of the current Git repository
                -w: Select the directory of a visible buffer
                -d: Select a sub-directory inside the current Git repository
                -g: Go to the root of the current Git working tree
      HELP
            ;;
          -p|)
            projects | pick cdv
            ;;
          -m)
            mountpoints | pick cdv
            ;;
          -r)
            remotes | pick cdv
            ;;
          -w)
            emacs-visible-directories | pick cdv
            ;;
          -d)
            project-subdirectories | pick cdv
            ;;
          -g)
            local root="$(git rev-parse --show-toplevel)"
            if [[ -n "$root" ]]; then
              builtin cd "$root"
            fi
            ;;
          *)
            builtin cd "$@"
            ;;
        esac
      }

      function clone() {
        if [[ $# -eq 0 ]]
        then
          echo "Usage: clone URL" >&2
          return 1
        else
          dir=''${$(emacsclient --eval "(expand-file-name (akirak-git-clone-dir \"$1\"))")//\"/}
          cd "$dir"
          echo "$dir"
        fi
      }

      function clock() {
        emacsclient -n --eval "(akirak-capture-clock-in
          (org-dog-complete-file \"Clock into file: \")
          \"$*\"
          :body (format \"[[file:%s]]\n%%?\" (abbreviate-file-name \"$PWD/\")))"
      }

      export NIX_BUILD_SHELL=bash

      export EDITOR=emacsclient

      # Use gpg-agent as ssh-agent.
      gpg-connect-agent /bye
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

      export STARSHIP_CONFIG=${pkgs.writeText "starship.toml" (pkgs.lib.fileContents ../etc/starship/starship.toml)}

      eval "$(${pkgs.starship}/bin/starship init zsh)"

      # https://github.com/MichaelAquilina/zsh-history-filter
      export HISTORY_FILTER_EXCLUDE=("TOKEN")
    '';
    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      "rm" = "rm -i";
      "j" = "journalctl -xe";
      "e" = "emacsclient -n";
      "start" = "systemctl --user start";
      "stop" = "systemctl --user stop";
      "enable" = "systemctl --user enable";
      "disable" = "systemctl --user disable";
      "reload" = "systemctl --user daemon-reload";
      "status" = "systemctl --user --full status";
      "restart" = "systemctl --user restart";
      "ssh-ignore" = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null";
    };
  };
}

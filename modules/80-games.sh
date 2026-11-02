# about: Terminal games: bsdgames, NetHack, Angband, Crawl, text adventures
apt_install \
    bsdgames bsdgames-nonfree \
    nethack-console angband crawl \
    frotz \
    ninvaders moon-buggy greed pacman4console nsnake \
    cmatrix sl fortune-mod cowsay
echo 'case ":$PATH:" in *:/usr/games:*) ;; *) PATH="$PATH:/usr/games";; esac' \
    > /etc/profile.d/games-path.sh

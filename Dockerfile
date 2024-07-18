FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update -y && \
apt-get upgrade -y && \
apt-get dist-upgrade -y && \
apt-get purge gnome -y && \
apt-get install -y shellinabox && \
apt-get install -y xfce4 && \
apt-get install -y xfce4-goodies && \
apt-get install -y systemd && \
apt-get install -y tightvncserver && \
apt-get install -y novnc && \
apt-get install -y net-tools && \
apt-get install -y nano && \
apt-get install -y vim && \
apt-get install -y neovim && \
apt-get install -y curl && \
apt-get install -y wget && \
apt-get install -y firefox && \
apt-get install -y git && \
apt-get install -y python3 && \
apt-get install -y python3-pip && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# xfce fixes
RUN update-alternatives --set x-terminal-emulator /usr/bin/xfce4-terminal.wrapper

# setup Chromium
RUN git clone https://github.com/scheib/chromium-latest-linux.git /chromium
RUN /chromium/update.sh

# VNC and noVNC config
ARG USER=root
ENV USER=${USER}

ARG VNCPORT=5900
ENV VNCPORT=${VNCPORT}
EXPOSE ${VNCPORT}

ARG NOVNCPORT=9090
ENV NOVNCPORT=${NOVNCPORT}
EXPOSE ${NOVNCPORT}

ARG VNCPWD=vncrootpower
ENV VNCPWD=${VNCPWD}

ARG VNCDISPLAY=1920x1080
ENV VNCDISPLAY=${VNCDISPLAY}

ARG VNCDEPTH=16
ENV VNCDEPTH=${VNCDEPTH}

# setup VNC
RUN mkdir -p /root/.vnc/
RUN echo ${VNCPWD} | vncpasswd -f > /root/.vnc/passwd
RUN chmod 600 /root/.vnc/passwd
RUN echo "#!/bin/sh \n\
xrdb $HOME/.Xresources \n\
xsetroot -solid grey \n\
#x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" & \n\
#x-window-manager & \n\
# Fix to make GNOME work \n\
export XKL_XMODMAP_DISABLE=1 \n\
/etc/X11/Xsession \n\
startxfce4 & \n\
" > /root/.vnc/xstartup
RUN chmod +x /root/.vnc/xstartup

# setup noVNC
RUN openssl req -new -x509 -days 365 -nodes \
  -subj "/C=US/ST=IL/L=Springfield/O=OpenSource/CN=localhost" \
  -out /etc/ssl/certs/novnc_cert.pem -keyout /etc/ssl/private/novnc_key.pem \
  > /dev/null 2>&1
RUN cat /etc/ssl/certs/novnc_cert.pem /etc/ssl/private/novnc_key.pem \
  > /etc/ssl/private/novnc_combined.pem
RUN chmod 600 /etc/ssl/private/novnc_combined.pem

RUN echo 'root:root' | chpasswd
# Expose the web-based terminal port
EXPOSE 4200

# Start shellinabox
CMD ["/usr/bin/shellinaboxd", "-t", "-s", "/:LOGIN"]

ENTRYPOINT [ "/bin/bash", "-c", " \
  echo 'NoVNC Certificate Fingerprint:'; \
  openssl x509 -in /etc/ssl/certs/novnc_cert.pem -noout -fingerprint -sha256; \
  vncserver :0 -rfbport ${VNCPORT} -geometry $VNCDISPLAY -depth $VNCDEPTH -localhost; \
  /usr/share/novnc/utils/launch.sh --listen $NOVNCPORT --vnc localhost:$VNCPORT \
    --cert /etc/ssl/private/novnc_combined.pem \
" ]

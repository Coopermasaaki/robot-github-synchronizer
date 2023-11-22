FROM openeuler/openeuler:23.03 as BUILDER
RUN dnf update -y && \
    dnf install -y golang && \
    go env -w GOPROXY=https://goproxy.cn,direct

MAINTAINER zengchen1024<chenzeng765@gmail.com>

# build binary
WORKDIR /go/src/github.com/opensourceways/robot-github-synchronizer
COPY . .
RUN GO111MODULE=on CGO_ENABLED=0 go build -a -o robot-github-synchronizer -buildmode=pie --ldflags "-s -linkmode 'external' -extldflags '-Wl,-z,now'" .

# copy binary config and utils
FROM openeuler/openeuler:22.03
RUN dnf -y update && \
    dnf in -y shadow && \
    dnf remove -y gdb-gdbserver && \
    groupadd -g 1000 robot-github-synchronizer && \
    useradd -u 1000 -g robot-github-synchronizer -s /sbin/nologin -m robot-github-synchronizer

RUN echo > /etc/issue && echo > /etc/issue.net && echo > /etc/motd
RUN mkdir /opt/app -p
RUN chmod 700 /opt/app
RUN chown robot-github-synchronizer:robot-github-synchronizer /opt/app

RUN echo 'set +o history' >> /root/.bashrc
RUN sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
RUN rm -rf /tmp/*

USER robot-github-synchronizer

WORKDIR /opt/app

COPY  --chown=robot-github-synchronizer --from=BUILDER /go/src/github.com/opensourceways/robot-github-synchronizer/robot-github-synchronizer /opt/app/robot-github-synchronizer

RUN chmod 550 /opt/app/robot-github-synchronizer

RUN echo "umask 027" >> /home/robot-github-synchronizer/.bashrc
RUN echo 'set +o history' >> /home/robot-github-synchronizer/.bashrc

ENTRYPOINT ["/opt/app/robot-github-synchronizer"]

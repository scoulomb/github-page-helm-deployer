FROM alpine/git

LABEL maintainer="Sylvain Coulombel <sylvaincoulombel@gmail.com>"

WORKDIR /working_dir

# helm install
# https://github.com/scoulomb/soapui-docker/blob/482dfe665c14fa8b71c6093dd07ee4739007b725/kubernetes_integration_example/README.md#install-helm
# https://www.shellhacks.com/alpine-install-curl/
RUN apk --no-cache add curl
RUN apk --no-cache add bash
RUN apk --no-cache add openssl
RUN curl --insecure -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
RUN chmod 700 get_helm.sh
RUN cat get_helm.sh
RUN sed -i 's/curl -SsL/curl --insecure -SsL/g' get_helm.sh
RUN bash get_helm.sh

COPY source source
RUN chmod u+x source/deliver_helm.sh

ENTRYPOINT ["source/deliver_helm.sh"]

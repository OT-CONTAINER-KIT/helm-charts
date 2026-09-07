# Image for kubelift/keycloak — built & pushed by BuildPiper.
#
# Pre-optimized: `kc.sh build` bakes the BUILD-TIME options into the image so the
# container starts with `kc.sh start --optimized` (no per-boot Quarkus augmentation).
# The chart must run it with  optimized: true  (or args: ["start","--optimized"]).
#
# Build-time options baked here (per `kc.sh build --help`) — change them HERE, not in values:
#   --db=postgres  --health-enabled=true
# Everything else — db URL/schema/credentials, cache, hostname, proxy, http, admin — is
# a run-time option and stays as env from the chart.

FROM quay.io/keycloak/keycloak:26.3.3 AS builder
RUN /opt/keycloak/bin/kc.sh build --db=postgres --health-enabled=true

FROM quay.io/keycloak/keycloak:26.3.3
COPY --from=builder /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
EXPOSE 8080 9000

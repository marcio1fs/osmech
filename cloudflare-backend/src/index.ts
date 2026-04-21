import { Container } from "@cloudflare/containers";

export class OsmechContainer extends Container {
  defaultPort = 8080;
  requiredPorts = [8080];
  sleepAfter = "30m";
  enableInternet = true;
  pingEndpoint = "/actuator/health";

  envVars = {
    SERVER_PORT: "8080",
  };
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const container = env.OSMECH_CONTAINER.getByName("osmech-backend");
    await container.startAndWaitForPorts({
      startOptions: {
        envVars: {
          SERVER_PORT: "8080",
          SPRING_PROFILES_ACTIVE: env.SPRING_PROFILES_ACTIVE,
          DB_URL: env.DB_URL,
          DB_USERNAME: env.DB_USERNAME,
          DB_PASSWORD: env.DB_PASSWORD,
          JWT_SECRET: env.JWT_SECRET,
          JWT_EXPIRATION: env.JWT_EXPIRATION,
          CORS_ORIGINS: env.CORS_ORIGINS,
          MERCADOPAGO_ACCESS_TOKEN: env.MERCADOPAGO_ACCESS_TOKEN,
          MERCADOPAGO_PUBLIC_KEY: env.MERCADOPAGO_PUBLIC_KEY,
          MERCADOPAGO_SUCCESS_URL: env.MERCADOPAGO_SUCCESS_URL,
          MERCADOPAGO_PENDING_URL: env.MERCADOPAGO_PENDING_URL,
          MERCADOPAGO_FAILURE_URL: env.MERCADOPAGO_FAILURE_URL,
          MERCADOPAGO_NOTIFICATION_URL: env.MERCADOPAGO_NOTIFICATION_URL,
          MERCADOPAGO_WEBHOOK_SECRET: env.MERCADOPAGO_WEBHOOK_SECRET,
          JPA_DDL_AUTO: env.JPA_DDL_AUTO,
          FLYWAY_ENABLED: env.FLYWAY_ENABLED,
          FLYWAY_BASELINE_ON_MIGRATE: env.FLYWAY_BASELINE_ON_MIGRATE,
          FLYWAY_BASELINE_VERSION: env.FLYWAY_BASELINE_VERSION
        },
      },
    });
    return container.fetch(request);
  },
};

export interface Env {
  OSMECH_CONTAINER: DurableObjectNamespace;
  SPRING_PROFILES_ACTIVE: string;
  DB_URL: string;
  DB_USERNAME: string;
  DB_PASSWORD: string;
  JWT_SECRET: string;
  JWT_EXPIRATION: string;
  CORS_ORIGINS: string;
  MERCADOPAGO_ACCESS_TOKEN: string;
  MERCADOPAGO_PUBLIC_KEY: string;
  MERCADOPAGO_SUCCESS_URL: string;
  MERCADOPAGO_PENDING_URL: string;
  MERCADOPAGO_FAILURE_URL: string;
  MERCADOPAGO_NOTIFICATION_URL: string;
  MERCADOPAGO_WEBHOOK_SECRET: string;
  JPA_DDL_AUTO: string;
  FLYWAY_ENABLED: string;
  FLYWAY_BASELINE_ON_MIGRATE: string;
  FLYWAY_BASELINE_VERSION: string;
}

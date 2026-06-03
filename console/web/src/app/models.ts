export interface ServiceStatus {
  name: string;
  status: string;
  detail: string;
}

export interface PolicySummary {
  name: string;
  type: string;
  enabled: boolean;
}

export interface ServiceStatus {
  name: string;
  status: string;
  detail: string;
}

export interface PolicySummary {
  id: number;
  name: string;
  type: string;
  enabled: boolean;
}

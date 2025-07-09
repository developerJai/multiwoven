import {
  Connector,
  ConnectorInfoResponse,
  ConnectorListResponse,
  CreateConnectorPayload,
  CreateConnectorResponse,
  TestConnectionPayload,
  TestConnectionResponse,
} from '@/views/Connectors/types';
import { apiRequest, multiwovenFetch } from './common';
import { RJSFSchema } from '@rjsf/utils';
import { buildUrlWithParams } from './utils';

export type ConnectorsDefinationApiResponse = {
  success: boolean;
  data?: Connector[];
};

type ConnectorDefinationApiResponse = {
  success: boolean;
  data?: {
    icon: string;
    name: string;
    connector_spec: {
      documentation_url: string;
      connection_specification: RJSFSchema;
      supports_normalization: boolean;
      supports_dbt: boolean;
      stream_type: string;
    };
  };
};

export const getConnectorsDefintions = async (connectorType: string): Promise<Connector[]> =>
  multiwovenFetch<null, Connector[]>({
    method: 'get',
    url: buildUrlWithParams('/connector_definitions', {
      type: connectorType,
    }),
  });

export const getConnectorDefinition = async (
  connectorType: string,
  connectorName: string,
): Promise<ConnectorDefinationApiResponse> => {
  return apiRequest(
    buildUrlWithParams(`/connector_definitions/${connectorName}`, { type: connectorType }),
    null,
  );
};

export const getConnectionStatus = async (payload: TestConnectionPayload) =>
  multiwovenFetch<TestConnectionPayload, TestConnectionResponse>({
    method: 'post',
    url: '/connector_definitions/check_connection',
    data: payload,
  });

export const createNewConnector = async (
  payload: CreateConnectorPayload,
): Promise<CreateConnectorResponse> =>
  multiwovenFetch<CreateConnectorPayload, CreateConnectorResponse>({
    method: 'post',
    url: '/connectors',
    data: payload,
  });

export const getConnectorInfo = async (id: string): Promise<ConnectorInfoResponse> =>
  multiwovenFetch<null, ConnectorInfoResponse>({
    method: 'get',
    url: `/connectors/${id}`,
  });

export const updateConnector = async (
  payload: CreateConnectorPayload,
  id: string,
): Promise<CreateConnectorResponse> =>
  multiwovenFetch<CreateConnectorPayload, CreateConnectorResponse>({
    method: 'put',
    url: `/connectors/${id}`,
    data: payload,
  });

export const getUserConnectors = async (connectorType: string, page?: string, perPage?: string): Promise<ConnectorListResponse> => {
  return multiwovenFetch<null, ConnectorListResponse>({
    method: 'get',
    url: buildUrlWithParams('/connectors', {
      type: connectorType,
      page: page,
      per_page: perPage
    }),
    data: null,
  });
};

export const deleteConnector = async (id: string): Promise<ConnectorInfoResponse> =>
  multiwovenFetch<null, ConnectorInfoResponse>({
    method: 'delete',
    url: `/connectors/${id}`,
  });

export const getAllConnectors = async (): Promise<ConnectorListResponse> =>
  multiwovenFetch<null, ConnectorListResponse>({
    method: 'get',
    url: '/connectors',
  });

// Interface for syncs by source response
export interface SyncsBySourceResponse {
  data: Array<{
    id: string;
    attributes: {
      name: string;
      source_id: string | number;
      [key: string]: any;
    };
  }>;
}

export const getSyncsBySourceId = async (sourceId: string): Promise<SyncsBySourceResponse> =>
  multiwovenFetch<null, SyncsBySourceResponse>({
    method: 'get',
    url: `/connectors/sources/${sourceId}/syncs`,
  });

// Response type for audience information
export interface AudienceInfoResponse {
  success: boolean;
  data: {
    id: string;
    type: string;
    attributes: {
      id: string;
      name: string;
      description?: string;
      created_at: string;
      updated_at: string;
    };
  };
};

// Get audience information by ID
export const getAudienceInfo = async (audienceId: string): Promise<AudienceInfoResponse> =>
  multiwovenFetch<null, AudienceInfoResponse>({
    method: 'get',
    // Using a more general endpoint structure - this should be adjusted based on actual API
    url: `/connectors/audiences/${audienceId}`,
  });

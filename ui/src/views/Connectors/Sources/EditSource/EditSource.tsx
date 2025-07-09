import {
  getConnectionStatus,
  getConnectorDefinition,
  getConnectorInfo,
  updateConnector,
  getSyncsBySourceId,
  SyncsBySourceResponse,
} from '@/services/connectors';
import { useMutation, useQuery } from '@tanstack/react-query';
import { useNavigate, useParams } from 'react-router-dom';

import { Box, Button, Divider, Text } from '@chakra-ui/react';
import TopBar from '@/components/TopBar';
import ContentContainer from '@/components/ContentContainer';
import { useEffect, useState } from 'react';
import { CreateConnectorPayload, TestConnectionPayload } from '../../types';
import { RJSFSchema } from '@rjsf/utils';
import Loader from '@/components/Loader';
import { Step } from '@/components/Breadcrumbs/types';
import EntityItem from '@/components/EntityItem';
import moment from 'moment';

import SourceActions from './SourceActions';
import { CustomToastStatus } from '@/components/Toast/index';
import useCustomToast from '@/hooks/useCustomToast';
import JSONSchemaForm from '../../../../components/JSONSchemaForm';
import { generateUiSchema } from '@/utils/generateUiSchema';
import { useStore } from '@/stores';
import FormFooter from '@/components/FormFooter';

const EditSource = (): JSX.Element => {
  const activeWorkspaceId = useStore((state) => state.workspaceId);

  const { sourceId } = useParams();
  const showToast = useCustomToast();
  const navigate = useNavigate();
  // Define an interface for our configuration with audience_id and name
interface ConnectorConfiguration {
  audience_id?: string;
  audience_name?: string;
  name?: string;
  [key: string]: any;
}

const [formData, setFormData] = useState<ConnectorConfiguration | null>(null);
const [audienceName, setAudienceName] = useState<string>('');
const [syncId, setSyncId] = useState<string>('');
  
const [isTestRunning, setIsTestRunning] = useState<boolean>(false);
const [testedFormData, setTestedFormData] = useState<ConnectorConfiguration | null>(null);

  const { data: connectorInfoResponse, isLoading: isConnectorInfoLoading } = useQuery({
    queryKey: ['connectorInfo', sourceId, activeWorkspaceId],
    queryFn: () => getConnectorInfo(sourceId as string),
    refetchOnMount: true,
    refetchOnWindowFocus: true,
    enabled: !!sourceId && activeWorkspaceId > 0,
  });

  const connectorInfo = connectorInfoResponse?.data;
  const connectorName = connectorInfo?.attributes?.connector_name;

  const { data: connectorDefinitionResponse, isLoading: isConnectorDefinitionLoading } = useQuery({
    queryKey: ['connector_definition', connectorName, activeWorkspaceId],
    queryFn: () => getConnectorDefinition('source', connectorName as string),
    refetchOnMount: false,
    refetchOnWindowFocus: false,
    enabled: !!connectorName && activeWorkspaceId > 0,
  });

  const connectorSchema = connectorDefinitionResponse?.data?.connector_spec;

  useEffect(() => {
    // Type cast the configuration to our ConnectorConfiguration interface
    const config = connectorInfo?.attributes?.configuration as ConnectorConfiguration;
    setFormData(config);
    
    // Set audience name from the connector attributes (not from config)
    if (connectorInfo?.attributes?.name) {
      console.log('Found connector name:', connectorInfo.attributes.name);
      setAudienceName(connectorInfo.attributes.name);
    }
  }, [connectorDefinitionResponse, connectorInfoResponse]);

  // Fetch associated sync for this source when connector info is available
  useEffect(() => {
    if (connectorInfo?.id) {
      const sourceId = connectorInfo.id;
      console.log('Fetching syncs for source ID:', sourceId);
      
      // Get all syncs associated with this source
      getSyncsBySourceId(sourceId)
        .then((response: SyncsBySourceResponse) => {
          console.log('Syncs response:', response);
          // If we have syncs, store the first one's ID
          if (response.data && response.data.length > 0) {
            const firstSync = response.data[0];
            console.log('Found sync:', firstSync);
            setSyncId(firstSync.id);
          } else {
            console.log('No syncs found for this source');
          }
        })
        .catch(error => {
          console.error('Error fetching syncs:', error);
        });
    }
  }, [connectorInfo]);

  const handleOnSaveChanges = async () => {
    if (!connectorInfo?.attributes) return;
    const payload: CreateConnectorPayload = {
      connector: {
        configuration: testedFormData,
        name: connectorInfo?.attributes?.name,
        connector_type: 'source',
        connector_name: connectorInfo?.attributes?.connector_name,
        description: connectorInfo?.attributes?.description ?? '',
      },
    };
    return updateConnector(payload, sourceId as string);
  };

  const { isPending: isEditLoading, mutate } = useMutation({
    mutationFn: handleOnSaveChanges,
    onSettled: () => {
      showToast({
        status: CustomToastStatus.Success,
        title: 'Success!!',
        description: 'Connector Updated',
        position: 'bottom-right',
        isClosable: true,
      });
      navigate('/setup/sources');
    },
    onError: () => {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Error!!',
        description: 'Something went wrong',
        position: 'bottom-right',
        isClosable: true,
      });
    },
  });

  const handleOnTestClick = async (formData: any) => {
    setIsTestRunning(true);

    if (!connectorInfo?.attributes) return;

    try {
      const payload: TestConnectionPayload = {
        connection_spec: formData,
        name: connectorInfo?.attributes?.connector_name,
        type: 'source',
      };

      const testingConnectionResponse = await getConnectionStatus(payload);
      const isConnectionSucceeded =
        testingConnectionResponse?.connection_status?.status === 'succeeded';

      if (isConnectionSucceeded) {
        showToast({
          status: CustomToastStatus.Success,
          title: 'Connection successful',
          position: 'bottom-right',
          isClosable: true,
        });

        return;
      }

      showToast({
        status: CustomToastStatus.Error,
        title: 'Connection failed',
        description: testingConnectionResponse?.connection_status?.message,
        position: 'bottom-right',
        isClosable: true,
      });
    } catch (e) {
      showToast({
        status: CustomToastStatus.Error,
        title: 'Connection failed',
        description: 'Something went wrong!',
        position: 'bottom-right',
        isClosable: true,
      });
    } finally {
      setIsTestRunning(false);
      // Properly type the form data
      const typedFormData = formData as ConnectorConfiguration;
      setTestedFormData(typedFormData);
    }
  };

  if (isConnectorInfoLoading || isConnectorDefinitionLoading) return <Loader />;

  const EDIT_SOURCE_STEPS: Step[] = [
    {
      name: 'Sources',
      url: '/setup/sources',
    },
    {
      name: connectorName || '',
      url: '',
    },
  ];

  const generatedSchema = generateUiSchema(connectorSchema?.connection_specification as RJSFSchema);

  return (
    <Box width='100%' display='flex' justifyContent='center'>
      <ContentContainer>
        <TopBar
          name={connectorName || ''}
          breadcrumbSteps={EDIT_SOURCE_STEPS}
          extra={
            <Box display='flex' alignItems='center'>
              <Box display='flex' alignItems='center'>
                <EntityItem
                  name={connectorInfo?.attributes?.connector_name || ''}
                  icon={connectorInfo?.attributes?.icon || ''}
                />
              </Box>
              <Divider
                orientation='vertical'
                height='24px'
                borderColor='gray.500'
                opacity='1'
                marginX='13px'
              />
              <Text size='sm' fontWeight='medium'>
                Last updated :{' '}
              </Text>
              <Text size='sm' fontWeight='semibold'>
                {moment(connectorInfo?.attributes?.updated_at).format('DD/MM/YYYY')}
              </Text>
              <SourceActions connectorType='sources' />
            </Box>
          }
        />

        <Box
          backgroundColor='gray.100'
          padding='24px'
          borderWidth='thin'
          borderRadius='8px'
          marginBottom='100px'
          border='1px'
          borderColor='gray.400'
        >
          {/* Display audience name if available */}
          {formData?.audience_id && audienceName && (
            <Box mb={4} bg="gray.200" p={3} borderRadius="md" display="flex" alignItems="center">
              <Text fontWeight="medium" marginRight="2">Audience:</Text>
              <Text 
                fontWeight="bold" 
                color="blue.600" 
                cursor="pointer" 
                textDecoration="underline"
                onClick={() => {
                  if (syncId) {
                    // Navigate to specific sync details page
                    navigate(`/activate/syncs/${syncId}`);
                  } else {
                    // Show a toast notification when no syncs are found
                    showToast({
                      title: 'No syncs found',
                      description: 'No syncs found for this source. Please create a sync first.',
                      status: CustomToastStatus.Warning,
                    });
                    // Stay on the same page (refresh the current EditSource view)
                    navigate(`/setup/sources/${sourceId}`);
                  }
                }}
              >
                {audienceName}
              </Text>
            </Box>
          )}
          <JSONSchemaForm
            schema={connectorSchema?.connection_specification as RJSFSchema}
            uiSchema={generatedSchema}
            formData={formData}
            onSubmit={(formData: FormData) => handleOnTestClick(formData)}
            onChange={(newFormData: any) => {
              const typedFormData = newFormData as ConnectorConfiguration;
              setFormData(typedFormData);
              // We don't need to update audience name on config changes
              // since we're using the connector's name from attributes
            }}
          >
            <FormFooter
              ctaName='Save Changes'
              ctaType='button'
              isCtaDisabled={!testedFormData}
              onCtaClick={mutate}
              isCtaLoading={isEditLoading}
              isAlignToContentContainer
              isDocumentsSectionRequired
              isContinueCtaRequired
              extra={
                <Button
                  marginRight='10px'
                  type='submit'
                  variant='ghost'
                  isLoading={isTestRunning}
                  minWidth={0}
                  width='auto'
                  backgroundColor='gray.300'
                >
                  Test Connection
                </Button>
              }
            />
          </JSONSchemaForm>
        </Box>
      </ContentContainer>
    </Box>
  );
};

export default EditSource;

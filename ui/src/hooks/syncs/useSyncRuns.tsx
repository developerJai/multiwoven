import { useQuery } from '@tanstack/react-query';
import { getSyncRunsBySyncId } from '@/services/syncs';

const useSyncRuns = (syncId: string, currentPage: number, activeWorkspaceId: number, status?: string) => {
  return useQuery({
    queryKey: ['activate', 'sync-runs', syncId, 'page-' + currentPage, activeWorkspaceId, status],
    queryFn: () => getSyncRunsBySyncId(syncId, currentPage.toString(), status),
    refetchOnMount: true,
    refetchOnWindowFocus: false,
    enabled: activeWorkspaceId > 0,
  });
};

export default useSyncRuns;

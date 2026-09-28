import { describe, it, expect, vi } from 'vitest';
import { createDeleteAccountHandler } from '../../api/delete-account';
import { deleteOwnedData, ownershipQueries } from '../../server/account-deletion';
import type { Firestore } from 'firebase-admin/firestore';

const now = 1_790_000_000;
function setup() {
  const response = { setHeader:vi.fn(), status:vi.fn(), json:vi.fn(), end:vi.fn() };
  response.status.mockReturnValue(response);
  const dependencies = { enabled:()=>true, verify:vi.fn().mockResolvedValue({uid:'owner',auth_time:now}), removeData:vi.fn(), removeIdentity:vi.fn(), now:()=>now*1000 };
  const request = { method:'POST', headers:{authorization:'Bearer fixture'}, body:{confirmation:'DELETE',uid:'victim'} };
  return { response, dependencies, request };
}
describe('account deletion authorization', () => {
  it('stays disabled until the server rollout is explicitly enabled', async () => {
    const {response,dependencies,request}=setup();dependencies.enabled=()=>false;
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(503);expect(dependencies.verify).not.toHaveBeenCalled();expect(dependencies.removeData).not.toHaveBeenCalled();
  });
  it('deletes only the verified UID, with identity last', async () => {
    const {response,dependencies,request}=setup();
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(dependencies.removeData).toHaveBeenCalledWith('owner');
    expect(dependencies.removeIdentity).toHaveBeenCalledWith('owner');
    expect(dependencies.removeData.mock.invocationCallOrder[0]).toBeLessThan(dependencies.removeIdentity.mock.invocationCallOrder[0]);
    expect(response.status).toHaveBeenCalledWith(200);
  });
  it.each([now-301,now+61,NaN])('rejects stale or invalid authentication: %s', async auth_time => {
    const {response,dependencies,request}=setup();dependencies.verify.mockResolvedValue({uid:'owner',auth_time});
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(401);expect(dependencies.removeData).not.toHaveBeenCalled();
  });
  it('rejects revoked credentials', async () => {
    const {response,dependencies,request}=setup();dependencies.verify.mockRejectedValue(new Error('revoked'));
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(401);expect(dependencies.removeData).not.toHaveBeenCalled();
  });
  it('requires explicit confirmation', async () => {
    const {response,dependencies,request}=setup();request.body.confirmation='';
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(400);expect(dependencies.removeData).not.toHaveBeenCalled();
  });
  it('keeps authentication retryable if data cleanup fails', async () => {
    const {response,dependencies,request}=setup();dependencies.removeData.mockRejectedValue(new Error('offline'));
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(503);expect(dependencies.removeIdentity).not.toHaveBeenCalled();
  });
  it.each(['GET','DELETE'])('does not accept %s', async method => {
    const {response,dependencies,request}=setup();request.method=method;
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(405);expect(dependencies.verify).not.toHaveBeenCalled();
  });
  it('rejects missing bearer tokens', async () => {
    const {response,dependencies,request}=setup();request.headers.authorization='';
    await createDeleteAccountHandler(dependencies)(request,response);
    expect(response.status).toHaveBeenCalledWith(401);expect(dependencies.removeData).not.toHaveBeenCalled();
  });
});
it('recursively removes nested user records and batches ownership queries', async () => {
  const queries:unknown[][]=[];
  const recursiveDelete=vi.fn();const marker=vi.fn();const doc=vi.fn(path=>({path,set:marker}));
  const db={doc,recursiveDelete,collection:(collection:string)=>({where:(field:string,op:string,uid:string)=>{queries.push([collection,field,op,uid]);return {limit:()=>({get:async()=>({empty:true,docs:[]})})};}})};
  await deleteOwnedData('owner',db as unknown as Firestore);
  for (const [collection,field] of ownershipQueries) expect(queries).toContainEqual([collection,field,'==','owner']);
  expect(recursiveDelete).toHaveBeenCalledWith(expect.objectContaining({path:'users/owner'}));
  expect(recursiveDelete).toHaveBeenCalledWith(expect.objectContaining({path:'public_profiles/owner'}));
  expect(doc).not.toHaveBeenCalledWith('subscriptionEntitlements/owner');
  expect(doc).toHaveBeenCalledWith('accountDeletions/owner');
  expect(marker.mock.invocationCallOrder[0]).toBeLessThan(recursiveDelete.mock.invocationCallOrder[0]);
});

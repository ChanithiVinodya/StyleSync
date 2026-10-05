using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;

namespace StyleSync.Api.Integrations
{
    public record ProjectRequestDetails(
        Guid RequestId,
        Guid ClientId,
        string ClientName,
        string ClientEmail,
        decimal MaxBudget,
        Guid AssignedDesignerId,
        string RoomType,
        double RoomSizeSqft,
        string StyleProfile
    );

    public interface IProjectRequestProvider
    {
        Task<ProjectRequestDetails> GetRequestDetailsAsync(Guid requestId);
        void RegisterStubRequest(ProjectRequestDetails details);
    }

    public class StubProjectRequestProvider : IProjectRequestProvider
    {
        private readonly ConcurrentDictionary<Guid, ProjectRequestDetails> _store = new();

        public StubProjectRequestProvider()
        {
            // Seed sample requests for tests and standalone operation
            var sampleId1 = Guid.Parse("00000000-0000-0000-0000-000000000001");
            var sampleId2 = Guid.Parse("00000000-0000-0000-0000-000000000002");

            _store[sampleId1] = new ProjectRequestDetails(
                RequestId: sampleId1,
                ClientId: Guid.Parse("11111111-1111-1111-1111-111111111111"),
                ClientName: "Kasun Silva",
                ClientEmail: "kasun@stylesync.lk",
                MaxBudget: 600000m,
                AssignedDesignerId: Guid.Parse("22222222-2222-2222-2222-222222222222"),
                RoomType: "Living room",
                RoomSizeSqft: 250,
                StyleProfile: "Minimalist"
            );

            _store[sampleId2] = new ProjectRequestDetails(
                RequestId: sampleId2,
                ClientId: Guid.Parse("33333333-3333-3333-3333-333333333333"),
                ClientName: "Amali Perera",
                ClientEmail: "amali@stylesync.lk",
                MaxBudget: 400000m,
                AssignedDesignerId: Guid.Parse("44444444-4444-4444-4444-444444444444"),
                RoomType: "Master bedroom",
                RoomSizeSqft: 180,
                StyleProfile: "Scandinavian"
            );
        }

        public Task<ProjectRequestDetails> GetRequestDetailsAsync(Guid requestId)
        {
            if (_store.TryGetValue(requestId, out var details))
            {
                return Task.FromResult(details);
            }

            // Fallback generation for any dynamic Request ID so integration tests don't break
            var generated = new ProjectRequestDetails(
                RequestId: requestId,
                ClientId: Guid.NewGuid(),
                ClientName: "Valued Client",
                ClientEmail: "client@stylesync.lk",
                MaxBudget: 1000000m,
                AssignedDesignerId: Guid.NewGuid(),
                RoomType: "Bedroom",
                RoomSizeSqft: 200,
                StyleProfile: "Modern"
            );

            _store[requestId] = generated;
            return Task.FromResult(generated);
        }

        public void RegisterStubRequest(ProjectRequestDetails details)
        {
            _store[details.RequestId] = details;
        }
    }
}

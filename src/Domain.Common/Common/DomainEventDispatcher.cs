using System.Collections.Concurrent;
using System.Reflection;
using Microsoft.Extensions.DependencyInjection;

namespace Domain.Common.Common;

public sealed class DomainEventDispatcher : IDomainEventDispatcher
{
    private static readonly ConcurrentDictionary<Type, MethodInfo> _handleMethodCache = new();

    private readonly IServiceProvider _serviceProvider;

    public DomainEventDispatcher(IServiceProvider serviceProvider)
    {
        ArgumentNullException.ThrowIfNull(serviceProvider);
        _serviceProvider = serviceProvider;
    }

    public async Task DispatchAsync(IEnumerable<IDomainEvent> events, CancellationToken cancellationToken = default)
    {
        foreach (var domainEvent in events)
        {
            var eventType = domainEvent.GetType();
            var handlerType = typeof(IDomainEventHandler<>).MakeGenericType(eventType);

            var handleMethod = _handleMethodCache.GetOrAdd(
                eventType,
                _ => handlerType.GetMethod("HandleAsync")
                    ?? throw new InvalidOperationException(
                        $"Method 'HandleAsync' not found on handler type '{handlerType.FullName}'."));

            var handlers = _serviceProvider.GetServices(handlerType);

            foreach (var handler in handlers)
            {
                var result = handleMethod.Invoke(handler, [domainEvent])
                    ?? throw new InvalidOperationException(
                        $"Handler '{handler?.GetType().FullName}' returned null from 'HandleAsync'. Handlers must return a non-null Task.");

                await ((Task)result).ConfigureAwait(false);
            }
        }
    }
}

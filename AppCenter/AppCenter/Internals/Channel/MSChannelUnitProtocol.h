#import <Foundation/Foundation.h>

#import "MSChannelProtocol.h"
#import "MSChannelUnitConfiguration.h"
#import "MSLog.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^enqueueCompletionBlock)(BOOL);

/**
 * `MSChannelUnitProtocol` represents a kind of channel that is able
 * to actually store/send logs (as opposed to a channel group, which
 * simply contains a collection of channel units).
 */
@protocol MSChannelUnitProtocol <MSChannelProtocol>

/**
 * The configuration used by this channel unit.
 */
@property(nonatomic) MSChannelUnitConfiguration *configuration;

/**
 * Enqueues a new log item.
 *
 * @param item The log item that should be enqueued.
 */
- (void)enqueueItem:(id<MSLog>)item;

@end

NS_ASSUME_NONNULL_END

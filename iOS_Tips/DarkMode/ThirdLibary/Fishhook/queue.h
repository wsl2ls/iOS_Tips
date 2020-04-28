#ifndef __LIBDS_QUEUE_H__
#define __LIBDS_QUEUE_H__

#include <stdint.h>

/*
 * DSQueue is a thread-safe queue that has no limitation on the number of
 * threads that can call ds_queue_put and ds_queue_get simultaneously.
 * That is, it supports a multiple producer and multiple consumer model.
 */

/* DSQueue implements a thread-safe queue using a fairly standard
 * circular buffer. */
struct DSQueue;

/* Allocates a new DSQueue with a buffer size of the capacity given. */
struct DSQueue *
ds_queue_create(uint32_t buffer_capacity);

/* Frees all data used to create a DSQueue. It should only be called after
 * a call to ds_queue_close to make sure all 'gets' are terminated before
 * destroying mutexes/condition variables.
 *
 * Note that the data inside the buffer is not freed. */
void
ds_queue_free(struct DSQueue *queue);

/* Returns the current length (number of items) in the queue. */
int
ds_queue_length(struct DSQueue *queue);

/* Returns the capacity of the queue. This is always equivalent to the
 * size of the initial buffer capacity. */
int
ds_queue_capacity(struct DSQueue *queue);

/* Closes a queue. A closed queue cannot add any new values.
 *
 * When a queue is closed, an empty queue will always be empty.
 * Therefore, `ds_queue_get` will return NULL and not block when
 * the queue is empty. Therefore, one can traverse the items in a queue
 * in a thread-safe manner with something like:
 *
 *  void *queue_item;
 *  while (NULL != (queue_item = ds_queue_get(queue)))
 *      do_something_with(queue_item);
 */
void
ds_queue_close(struct DSQueue *queue);

/* Adds new values to a queue (or "sends values to a consumer").
 * `ds_queue_put` cannot be called with a queue that has been closed. If
 * it is, an assertion error will occur. 
 * If the queue is full, `ds_queue_put` will block until it is not full,
 * in which case the value will be added to the queue. */
void
ds_queue_put(struct DSQueue *queue, void *item);

/* Reads new values from a queue (or "receives values from a producer").
 * `ds_queue_get` will block if the queue is empty until a new value has been
 * added to the queue with `ds_queue_put`. In which case, `ds_queue_get` will
 * return the next item in the queue.
 * `ds_queue_get` can be safely called on a queue that has been closed (indeed,
 * this is probably necessary). If the queue is closed and not empty, the next
 * item in the queue is returned. If the queue is closed and empty, it will
 * always be empty, and therefore NULL will be returned immediately. */
void *
ds_queue_get(struct DSQueue *queue);

#endif

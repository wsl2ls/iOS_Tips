#include <assert.h>
#include <pthread.h>
#include <semaphore.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>

#include "queue.h"


struct DSQueue {
    /* An array of elements in the queue. */
    void **buf;

    /* The position of the first element in the queue. */
    uint32_t pos;

    /* The number of items currently in the queue.
     * When `length` = 0, ds_queue_get will block.
     * When `length` = `capacity`, ds_queue_put will block. */
    uint32_t length;

    /* The total number of allowable items in the queue */
    uint32_t capacity;

    /* When true, the queue has been closed. A run-time error will occur
     * if a value is sent to a closed queue. */
    bool closed;

    /* Guards the modification of `length` (a condition variable) and `pos`. */
    pthread_mutex_t mutate;

    /* A condition variable that is pinged whenever `length` has changed or
     * when the queue has been closed. */
    pthread_cond_t cond_length;
};


struct DSQueue *
ds_queue_create(uint32_t buffer_capacity)
{
    struct DSQueue *queue;
    int errno;

    assert(buffer_capacity > 0);

    queue = malloc(sizeof(*queue));
    assert(queue);

    queue->pos = 0;
    queue->length = 0;
    queue->capacity = buffer_capacity;
    queue->closed = false;

    queue->buf = malloc(buffer_capacity * sizeof(*queue->buf));
    assert(queue->buf);

    if (0 != (errno = pthread_mutex_init(&queue->mutate, NULL))) {
        fprintf(stderr, "Could not create mutex. Errno: %d\n", errno);
        exit(1);
    }
    if (0 != (errno = pthread_cond_init(&queue->cond_length, NULL))) {
        fprintf(stderr, "Could not create cond var. Errno: %d\n", errno);
        exit(1);
    }

    return queue;
}

void
ds_queue_free(struct DSQueue *queue)
{
    int errno;

    if (0 != (errno = pthread_mutex_destroy(&queue->mutate))) {
        fprintf(stderr, "Could not destroy mutex. Errno: %d\n", errno);
        exit(1);
    }
    if (0 != (errno = pthread_cond_destroy(&queue->cond_length))) {
        fprintf(stderr, "Could not destroy cond var. Errno: %d\n", errno);
        exit(1);
    }
    free(queue->buf);
    free(queue);
}

int
ds_queue_length(struct DSQueue *queue)
{
    int len;
    pthread_mutex_lock(&queue->mutate);
    len = queue->length;
    pthread_mutex_unlock(&queue->mutate);
    return len;
}

int
ds_queue_capacity(struct DSQueue *queue)
{
    return queue->capacity;
}

void
ds_queue_close(struct DSQueue *queue)
{
    pthread_mutex_lock(&queue->mutate);
    queue->closed = true;
    pthread_cond_broadcast(&queue->cond_length);
    pthread_mutex_unlock(&queue->mutate);
}

void
ds_queue_put(struct DSQueue *queue, void *item)
{
    pthread_mutex_lock(&queue->mutate);
    assert(!queue->closed);

    while (queue->length == queue->capacity)
        pthread_cond_wait(&queue->cond_length, &queue->mutate);

    assert(!queue->closed);
    assert(queue->length < queue->capacity);

    queue->buf[(queue->pos + queue->length) % queue->capacity] = item;
    queue->length++;
    pthread_cond_broadcast(&queue->cond_length);

    pthread_mutex_unlock(&queue->mutate);
}

void *
ds_queue_get(struct DSQueue *queue)
{
    void *item;

    pthread_mutex_lock(&queue->mutate);

    while (queue->length == 0) {
        /* This is a bit tricky. It is possible that the queue has been closed
         * *and* has become empty while `pthread_cond_wait` is blocking.
         * Therefore, it is necessary to always check if the queue has been
         * closed when the queue is empty, otherwise we will deadlock. */
        if (queue->closed) {
            pthread_mutex_unlock(&queue->mutate);
            return NULL;
        }
        pthread_cond_wait(&queue->cond_length, &queue->mutate);
    }

    assert(queue->length <= queue->capacity);
    assert(queue->length > 0);

    item = queue->buf[queue->pos];
    queue->buf[queue->pos] = NULL;
    queue->pos = (queue->pos + 1) % queue->capacity;

    queue->length--;
    pthread_cond_broadcast(&queue->cond_length);

    pthread_mutex_unlock(&queue->mutate);

    return item;
}

package io.ably.flutter.plugin;

import android.util.LongSparseArray;

import io.ably.lib.realtime.AblyRealtime;
import io.ably.lib.rest.AblyRest;
import io.ably.lib.types.AblyException;
import io.ably.lib.types.ClientOptions;

class AblyLibrary {
    private boolean _disposed = false;
    private long _nextHandle = 1;

    //    using LongSparseArray as suggested by Studio
    //    and as per this answer https://stackoverflow.com/a/31413003
    private final LongSparseArray<AblyRest> _restInstances = new LongSparseArray<>();
    private final LongSparseArray<AblyRealtime> _realtimeInstances = new LongSparseArray<>();

    private void assertNotDisposed() {
        if (_disposed) {
            throw new IllegalStateException("Instance disposed.");
        }
    }

    long createRealtime(final ClientOptions clientOptions) throws AblyException {
        assertNotDisposed();

        final AblyRealtime realtime = new AblyRealtime(clientOptions);
        _realtimeInstances.put(_nextHandle, realtime);
        return _nextHandle++;
    }

    long createRest(final ClientOptions clientOptions) throws AblyException {
        assertNotDisposed();

        final AblyRest rest = new AblyRest(clientOptions);
        _restInstances.put(_nextHandle, rest);
        return _nextHandle++;
    }

    AblyRealtime getRealtime(final long handle) {
        assertNotDisposed();

        return _realtimeInstances.get(handle);
    }

    AblyRest getRest(final long handle){
        assertNotDisposed();

        return _restInstances.get(handle);
    }

    void dispose() {
        assertNotDisposed();

        _disposed = true;

        for(int i=0; i<_realtimeInstances.size(); i++){
            long key = _realtimeInstances.keyAt(i);
            AblyRealtime r = _realtimeInstances.get(key);
            try {
                r.close();
            } catch (Throwable t) {
                t.printStackTrace();
            }
        }
        _realtimeInstances.clear();
        _restInstances.clear();
    }
}

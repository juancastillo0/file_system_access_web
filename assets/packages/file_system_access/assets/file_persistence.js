//
/** @type {<T>(name: string, objectStore: string) => Promise<{
 * put: (v:T, k?:IDBValidKey) => Promise<IDBValidKey>
 * get: (k:IDBValidKey | IDBKeyRange) => Promise<T?>
 * clear: () => Promise<void>
 * getAll: (query?:IDBValidKey | IDBKeyRange, count?:number) => Promise<Array<T>>
 * delete: (k:IDBValidKey | IDBKeyRange) => Promise<undefined>
 * }}> */
const openDB = (name, objectStore) => {
  return new Promise((resolve, reject) => {
    const dbReq = window.indexedDB.open(name, 1);
    dbReq.onupgradeneeded = (e) => {
      dbReq.result.createObjectStore(objectStore, {
        autoIncrement: false,
        keyPath: "id",
      });
    };
    dbReq.onsuccess = (e) => {
      /** @type {(exec: <T>(s:IDBObjectStore) => IDBRequest<T>, mode: IDBTransactionMode) => Promise<T>} */
      const generic = (exec, mode) => {
        return new Promise((resolve, reject) => {
          const tx = dbReq.result.transaction(objectStore, mode);
          const req = exec(tx.objectStore(objectStore));
          req.onsuccess = (e) => tx.commit();
          req.onerror = (e) => tx.abort();

          tx.oncomplete = (e) => resolve(req.result);
          tx.onerror = (e) => reject(e);
          tx.onabort = (e) => reject(e);
        });
      };

      resolve({
        put: (value, key) =>
          generic((store) => store.put(value, key), "readwrite"),
        delete: (query) => generic((store) => store.delete(query), "readwrite"),
        clear: () => generic((store) => store.clear(), "readwrite"),
        get: (id) => generic((store) => store.get(id), "readonly"),
        getAll: (query, count) =>
          generic((store) => store.getAll(query, count), "readonly"),
      });
    };

    dbReq.onerror = (e) => reject(e);
    dbReq.onblocked = (e) => reject(e);
  });
};

if ("showOpenFilePicker" in window) {
  /** @type {Promise<{allMap: Map<number, any>; allValueMap: Map<any, any>; put: (v: any) => Promise<number>;}>} */
  const _db = openDB("FilesDB", "FilesObjectStore").then((db) =>
    db.getAll().then((all) => {
      // Make maps
      const allMap = new Map(all.map((v) => [v.id, v]));
      const allValueMap = new Map(all.map((v) => [v.value, v]));
      let maxId = Math.max(...allMap.keys(), 0);

      return {
        allMap,
        allValueMap,
        valuesIterable: () => allMap.values(),
        getAll: () => [...allMap.values()],
        keys: () => [...allMap.keys()],
        get: (id) => allMap.get(id),
        delete: async (id) => {
          const item = allMap.get(id);
          if (!item) return undefined;

          return db.delete(id).then(() => {
            allMap.delete(id);
            allValueMap.delete(item.value);
            return item;
          });
        },
        put: async (v) => {
          const s = Object.getOwnPropertySymbols(v).find(
            (s) => String(s) === "Symbol(_dartObj)"
          );
          if (s) {
            v = v[s];
          }
          // Retrieve by value
          const _saved = allValueMap.get(v);
          if (_saved) return _saved;
          // Retrieve by isSameEntry
          for (const [key, value] of allMap) {
            const c = value.value;
            if (
              v.name === c.name &&
              v.kind === c.kind &&
              (await v.isSameEntry(value.value))
            ) {
              // TODO: should be list of items
              return value;
            }
          }
          // It's not saved, save it
          maxId += 1;
          const item = { value: v, id: maxId, savedDate: new Date() };

          return db.put(item).then((id) => {
            allMap.set(id, item);
            allValueMap.set(item.value, item);
            return item;
          });
        },
      };
    })
  );

  window.getFileSystemAccessFilePersistence = () => {
    return _db;
  };
  //   const prev = window.showDirectoryPicker;
  //   window.showDirectoryPicker = function () {
  //     return prev(arguments).then((v) => {
  //       v.saveInIndexedDB = () => {
  //         return _db.then((db) =>
  //           db.put(v).then((k) => {
  //             return k;
  //           })
  //         );
  //       };
  //       // v.saveInIndexedDB();

  //       // v.deleteFromIndexedDB = () => {
  //       //   if (!key) return;
  //       //   return _db.then((db) =>
  //       //     db.put(v).then((k) => {
  //       //       key = k;
  //       //       return k;
  //       //     })
  //       //   );
  //       // };
  //       return v;
  //     });
  //   };
}

Module['noInitialRun'] = true;
Module['onRuntimeInitialized'] = function () {
  var sp = stackSave();
  try {
    Module['_main']();
  } catch (error) {
    if (error !== 'unwind') {
      throw error;
    }
  } finally {
    stackRestore(sp);
  }
};

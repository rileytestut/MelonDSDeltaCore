var videoArray = new Array(256 * 384 * 2).fill(0);
var videoString = "0".repeat(256 * 384 * 2);

function canvasBounds() {
    var r = document.getElementById('canvas').getBoundingClientRect();
    return '{{'+r.left+','+r.top+'},{'+r.width+','+r.height+'}}';
}

var myIndex = 0;

const mapBytes = async (array) => {
    
    var result = await Promise.all(array.map(async (character, index) => {
        videoArray[index] = String.fromCharCode(character);
//        var substring = String.fromCharCode(character);
        return character;
    }));
    
    var binary = result.join("");
    window.webkit.messageHandlers.DLTAEmulatorBridge.postMessage({'type': 'video', 'data': binary});
}

function MelonDSPrepareCore()
{
    console.log("Initializing...");
    
    var directoryPathPtr = allocate(intArrayFromString(''), ALLOC_NORMAL);
    var resourcesPathPtr = allocate(intArrayFromString(''), ALLOC_NORMAL);
    var bios7PathPtr = allocate(intArrayFromString('biosnds7.rom'), ALLOC_NORMAL);
    var bios9PathPtr = allocate(intArrayFromString('biosnds9.rom'), ALLOC_NORMAL);
    var firmwarePathPtr = allocate(intArrayFromString('firmware.bin'), ALLOC_NORMAL);
    
    _MelonDSInitialize(directoryPathPtr, resourcesPathPtr, bios7PathPtr, bios9PathPtr, firmwarePathPtr);
    
    _free(firmwarePathPtr);
    _free(bios9PathPtr);
    _free(bios7PathPtr);
    _free(resourcesPathPtr);
    _free(directoryPathPtr);
        
    var videoCallback = addFunction(function(offset, size) {
        
        var startTime = performance.now()
        
        var typedArray = HEAPU16.subarray(offset/2, offset/2 + size/2);
//        var array = Array.from(typedArray);
        
//        var binary = '';
//        var len = typedArray.length;
//        for (var i = 0; i < len; i++) {
//            binary += String.fromCharCode( typedArray[ i ] );
//        }
        
//        mapBytes(array).then(function() {
//            var endTime = performance.now();
//
//            var duration = endTime - startTime;
//            console.log("[RSTLog] Video Callback: " + duration + " milliseconds");
//        });
//
        
        var len = typedArray.length;
        for (var i = 0; i < len; i++) {
            videoArray[i] = String.fromCharCode(typedArray[i]);
        }
        
        var binary = videoArray.join("");
        window.webkit.messageHandlers.DLTAEmulatorBridge.postMessage({'type': 'video', 'data': binary});
        
    }, 'vii');

    _MelonDSSetVideoCallback(videoCallback);

    var audioCallback = addFunction(function(buffer, size) {
      var typedArray = Module.HEAPU8.subarray(buffer, buffer + size);
      var array = Array.from(typedArray);
      window.webkit.messageHandlers.DLTAEmulatorBridge.postMessage({'type': 'audio', 'data': array});
    }, 'vii');

    _MelonDSSetAudioCallback(audioCallback);

    var saveCallback = addFunction(function() {
      window.webkit.messageHandlers.DLTAEmulatorBridge.postMessage({'type': 'save'});
    }, 'v');

    _MelonDSSetSaveCallback(saveCallback);

    window.webkit.messageHandlers.DLTAEmulatorBridge.postMessage({'type': 'ready'});
}

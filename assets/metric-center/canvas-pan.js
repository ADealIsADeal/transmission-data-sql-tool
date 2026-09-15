    // Drag the scrollable canvas; a short press still selects a table card.
    function enableCanvasPan(canvas){
      let drag=null,suppressClick=false;
      canvas.title='按住鼠标左键拖动画布';
      canvas.addEventListener('pointerdown',e=>{
        if(e.pointerType!=='mouse'||e.button!==0)return;
        suppressClick=false;
        drag={id:e.pointerId,x:e.clientX,y:e.clientY,left:canvas.scrollLeft,top:canvas.scrollTop,moved:false};
      });
      window.addEventListener('pointermove',e=>{
        if(!drag||drag.id!==e.pointerId)return;
        if(!drag.moved&&Math.hypot(e.clientX-drag.x,e.clientY-drag.y)<5)return;
        if(!drag.moved){drag.moved=true;canvas.setPointerCapture(e.pointerId);canvas.classList.add('canvas-dragging')}
        e.preventDefault();
        canvas.scrollLeft=drag.left-(e.clientX-drag.x);
        canvas.scrollTop=drag.top-(e.clientY-drag.y);
      },{passive:false});
      function finish(e){
        if(!drag||drag.id!==e.pointerId)return;
        suppressClick=drag.moved;drag=null;canvas.classList.remove('canvas-dragging');
        if(canvas.hasPointerCapture(e.pointerId))canvas.releasePointerCapture(e.pointerId);
      }
      window.addEventListener('pointerup',finish);
      window.addEventListener('pointercancel',finish);
      canvas.addEventListener('lostpointercapture',finish);
      canvas.addEventListener('click',e=>{if(suppressClick){e.preventDefault();e.stopImmediatePropagation();suppressClick=false}},true);
    }
    ['tableGraph','hbGraph'].forEach(id=>enableCanvasPan(document.getElementById(id)));


$('.container').fadeOut(0)

window.addEventListener('message' ,function(e){

    if(e.data!=null){
        
        if(e.data.action === 'show'){
            $('.container').append(`
                <span class="StaticText"><span class="keyZone">${e.data.key} </span></span>
                
            `)
            $('.container').fadeIn('fast')            
        }

        if(e.data.action === 'hide'){
            $('.container').html('')
            $('.container').fadeOut('fast')
        }

    }

})
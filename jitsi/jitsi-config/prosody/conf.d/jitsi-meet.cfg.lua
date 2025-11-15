




















admins = {
    "focus@auth.localhost",
    "jvb@auth.localhost"
}

unlimited_jids = {
    "focus@auth.localhost",
    "jvb@auth.localhost"
}

plugin_paths = { "/prosody-plugins/", "/prosody-plugins-custom" }

muc_mapper_domain_base = "localhost";
muc_mapper_domain_prefix = "muc";

http_default_host = "localhost"









consider_bosh_secure = true;
consider_websocket_secure = true;



VirtualHost "localhost"

  
    authentication = "token"
    app_id = "collabsphere"
    app_secret = "dev-jitsi-secret-change-in-production"
    allow_empty_token = true
    
  

    ssl = {
        key = "/config/certs/localhost.key";
        certificate = "/config/certs/localhost.crt";
    }
    modules_enabled = {
        "bosh";
        
        "websocket";
        "smacks"; -- XEP-0198: Stream Management
        
        "pubsub";
        "ping";
        "speakerstats";
        "conference_duration";
        
        
        "muc_lobby_rooms";
        
        
        "muc_breakout_rooms";
        
        
        "av_moderation";
        
        
        
        
    }

    main_muc = "muc.localhost"

    
    lobby_muc = "lobby.localhost"
    
    

    

    
    breakout_rooms_muc = "breakout.localhost"
    

    speakerstats_component = "speakerstats.localhost"
    conference_duration_component = "conferenceduration.localhost"

    
    av_moderation_component = "avmoderation.localhost"
    

    c2s_require_encryption = false


VirtualHost "guest.meet.jitsi"
    authentication = "jitsi-anonymous"

    c2s_require_encryption = false


VirtualHost "auth.localhost"
    ssl = {
        key = "/config/certs/auth.localhost.key";
        certificate = "/config/certs/auth.localhost.crt";
    }
    modules_enabled = {
        "limits_exception";
    }
    authentication = "internal_hashed"



Component "internal-muc.localhost" "muc"
    storage = "memory"
    modules_enabled = {
        "ping";
        }
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true

Component "muc.localhost" "muc"
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        "token_verification";
        
        "polls";
        "muc_domain_mapper";
        }
    muc_room_cache_size = 1000
    muc_room_locking = false
    muc_room_default_public_jids = true
    Component "focus.localhost" "client_proxy"
    target_address = "focus@auth.localhost"

Component "speakerstats.localhost" "speakerstats_component"
    muc_component = "muc.localhost"

Component "conferenceduration.localhost" "conference_duration_component"
    muc_component = "muc.localhost"


Component "avmoderation.localhost" "av_moderation_component"
    muc_component = "muc.localhost"



Component "lobby.localhost" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true



Component "breakout.localhost" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
    modules_enabled = {
        "muc_meeting_id";
        "muc_domain_mapper";
        "polls";
        }


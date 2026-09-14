with base_union as (
    select
        peer_id
        , user_id
        , guid
        , parent_id
        , seqid
        , event_id
        , cast(server_info as string) as server_info
        , cmdid
        , appid
        , service_version
        , product_version
        , service_name
        , extdata_head
        , process_id
        , ip
        , attribute1
        , attribute2
        , cost1
        , cost2
        , cost3
        , cost4
        , final_result
        , '' as event_status
        , mode
        , file_name
        , file_suffix
        , file_size
        , extdata
        , cdn_res_count
        , dcdn_hub_res_num
        , high_res_count
        , error_code
        , task_type
        , hub_gcid
        , real_gcid
        , download_time
        , recv_bytes
        , vip_type
        , anti_server
        , task_origin
        , ref_url
        , file_url
        , cast(global_speed as bigint) as global_speed
        , download_strategy
        , token
        , error_bytes
        , index_extra_data
        , ts
        , jiasu_vip_speed
        , jiasu_super_speed
        , jiasu_smooth
        , jiasu_zero_speed
        , jiasu_group
        , all_bytes
        , origin_bytes
        , server_bytes
        , phub_bytes
        , phub_peer
        , tracker_bytes
        , tracker_peer
        , dcdn_bytes
        , dcdn_peer
        , pcdn_bytes
        , pcdn_peer
        , bonus_bytes
        , bonus_peer
        , phub_cdn_bytes
        , phub_dcdn_bytes
        , xphub_bytes
        , super_pcdn_bytes
        , super_pcdn_peer
        , phub_res_peer
        , phub_insert_peer
        , running_task_count_avg
        , running_user_task_count_avg
        , global_all_bytes
        , global_p2p_bytes
        , global_p2s_bytes
        , global_bonus_bytes
        , global_dcdn_bytes
        , global_origin_bytes
        , etag
        , query_all_hub_count
        , query_all_hub_result
        , global_speed_target_1
        , global_speed_target_64
        , first_insert_pcdn_peer_time
        , alloc_data_buffer_fail_count
        , global_speed_max_in_window
        , ending_span_time
        , is_netdisk_fetch_task
        , first_video_mode
        , cast(null as string) as player_mode
        , platform
        , case
            when coalesce(is_netdisk_fetch_task, '0') = '1' then 'withdraw'
            when first_video_mode = '2' then 'play'
            else 'download'
            end action_type
        , row_number() over(partition by platform, seqid, parent_id, file_url, peer_id order by ts desc) as rn
    from
        dw_xlyun.dwd_xlyun_transfer_pc_log_h_inc
    where
        ds = '${date}'

    union all

    select
        peer_id
        , coalesce(user_id_parsed, user_id) as user_id
        , guid
        , parent_id
        , cast(seqid as string) as seqid
        , event_id
        , cast(server_info as string) server_info
        , cmdid
        , appid
        , service_version
        , product_version
        , service_name
        , extdata_head
        , process_id
        , ip
        , '' as attribute1
        , '' as attribute2
        , 0 as cost1
        , 0 as cost2
        , 0 as cost3
        , 0 as cost4
        , final_result
        , cast(event_status as string) as event_status
        , mode
        , file_name
        , file_suffix
        , file_size
        , extdata
        , cdn_res_count
        , dcdn_hub_res_num
        , high_res_count
        , error_code
        , task_type
        , hub_gcid
        , real_gcid
        , download_time
        , recv_bytes
        , vip_type
        , anti_server
        , task_origin
        , ref_url
        , file_url
        , cast(global_speed as bigint) as global_speed
        , download_strategy
        , token
        , error_bytes
        , index_extra_data
        , ts
        , jiasu_vip_speed
        , jiasu_super_speed
        , jiasu_smooth
        , jiasu_zero_speed
        , jiasu_group
        , all_bytes
        , origin_bytes
        , server_bytes
        , phub_bytes
        , phub_peer
        , tracker_bytes
        , tracker_peer
        , dcdn_bytes
        , dcdn_peer
        , pcdn_bytes
        , pcdn_peer
        , bonus_bytes
        , bonus_peer
        , phub_cdn_bytes
        , phub_dcdn_bytes
        , xphub_bytes
        , super_pcdn_bytes
        , super_pcdn_peer
        , phub_res_peer
        , phub_insert_peer
        , running_task_count_avg
        , running_user_task_count_avg
        , global_all_bytes
        , global_p2p_bytes
        , global_p2s_bytes
        , global_bonus_bytes
        , global_dcdn_bytes
        , global_origin_bytes
        , '' as etag
        , query_all_hub_count
        , query_all_hub_result
        , cast(split(str_to_map(xl_urldecode(extdata['LevelStrategy']), ';', '\\|')['1'], '-')[0] as bigint) as global_speed_target_1
        , cast(split(str_to_map(xl_urldecode(extdata['LevelStrategy']), ';', '\\|')['64'], '-')[0] as bigint) as global_speed_target_64
        , first_insert_pcdn_peer_time
        , alloc_data_buffer_fail_count
        , global_speed_max_in_window
        , ending_span_time
        , cast(null as string) as is_netdisk_fetch_task
        , cast(null as string) as first_video_mode
        , player_mode
        , platform
        , case
            when task_type in ('1', '3', '4', '16') or (task_type = '12' and player_mode = '-1' ) then 'download'
            when task_type in ('12','14') and player_mode = '2' then 'withdraw'
            when task_type in ('12','14') and player_mode in('0', '1') then 'play'
            else 'other'
            end as action_type
        , row_number() over(partition by platform, seqid, parent_id, file_url, peer_id order by ts desc) as rn
    from
        dw_xlyun.dwd_xlyun_transfer_log_h_inc
    where
        ds = '${date}'
)

insert overwrite table dw_xlyun.dwd_xlyun_transfer_seqid_platform_dedup_d_inc partition (ds = '${date}', platform, action_type)
select
    ranked.peer_id
    , ranked.user_id
    , ranked.guid
    , ranked.parent_id
    , ranked.seqid
    , ranked.event_id
    , ranked.server_info
    , ranked.cmdid
    , ranked.appid
    , ranked.service_version
    , ranked.product_version
    , ranked.service_name
    , ranked.extdata_head
    , ranked.process_id
    , ranked.ip
    , ranked.attribute1
    , ranked.attribute2
    , ranked.cost1
    , ranked.cost2
    , ranked.cost3
    , ranked.cost4
    , ranked.final_result
    , ranked.event_status
    , ranked.mode
    , ranked.file_name
    , ranked.file_suffix
    , ranked.file_size
    , ranked.extdata
    , ranked.cdn_res_count
    , ranked.dcdn_hub_res_num
    , ranked.high_res_count
    , ranked.error_code
    , ranked.task_type
    , ranked.hub_gcid
    , ranked.real_gcid
    , ranked.download_time
    , ranked.recv_bytes
    , ranked.vip_type
    , ranked.anti_server
    , ranked.task_origin
    , ranked.ref_url
    , ranked.file_url
    , ranked.global_speed
    , ranked.download_strategy
    , ranked.token
    , ranked.error_bytes
    , ranked.index_extra_data
    , ranked.ts
    , ranked.jiasu_vip_speed
    , ranked.jiasu_super_speed
    , ranked.jiasu_smooth
    , ranked.jiasu_zero_speed
    , ranked.jiasu_group
    , ranked.all_bytes
    , ranked.origin_bytes
    , ranked.server_bytes
    , ranked.phub_bytes
    , ranked.phub_peer
    , ranked.tracker_bytes
    , ranked.tracker_peer
    , ranked.dcdn_bytes
    , ranked.dcdn_peer
    , ranked.pcdn_bytes
    , ranked.pcdn_peer
    , ranked.bonus_bytes
    , ranked.bonus_peer
    , ranked.phub_cdn_bytes
    , ranked.phub_dcdn_bytes
    , ranked.xphub_bytes
    , ranked.super_pcdn_bytes
    , ranked.super_pcdn_peer
    , ranked.phub_res_peer
    , ranked.phub_insert_peer
    , ranked.running_task_count_avg
    , ranked.running_user_task_count_avg
    , ranked.global_all_bytes
    , ranked.global_p2p_bytes
    , ranked.global_p2s_bytes
    , ranked.global_bonus_bytes
    , ranked.global_dcdn_bytes
    , ranked.global_origin_bytes
    , ranked.etag
    , ranked.query_all_hub_count
    , ranked.query_all_hub_result
    , ranked.global_speed_target_1
    , ranked.global_speed_target_64
    , ranked.first_insert_pcdn_peer_time
    , ranked.alloc_data_buffer_fail_count
    , ranked.global_speed_max_in_window
    , ranked.ending_span_time
    , ranked.is_netdisk_fetch_task
    , ranked.first_video_mode
    , ranked.player_mode
    , ranked.platform
    , ranked.action_type
from
    base_union as ranked
where
    ranked.rn = 1
;

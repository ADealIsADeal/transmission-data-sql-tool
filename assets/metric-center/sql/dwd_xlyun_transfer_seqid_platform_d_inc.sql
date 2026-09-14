with joined as (
    select
        d.peer_id
        , d.user_id
        , d.guid
        , d.parent_id
        , d.seqid
        , d.event_id
        , d.server_info
        , d.cmdid
        , d.appid
        , d.service_version
        , d.product_version
        , d.service_name
        , d.extdata_head
        , d.process_id
        , d.ip
        , d.attribute1
        , d.attribute2
        , d.cost1
        , d.cost2
        , d.cost3
        , d.cost4
        , d.final_result
        , d.event_status
        , d.mode
        , d.file_name
        , d.file_suffix
        , d.file_size
        , d.extdata
        , d.cdn_res_count
        , d.dcdn_hub_res_num
        , d.high_res_count
        , d.error_code
        , d.task_type
        , d.hub_gcid
        , d.real_gcid
        , d.download_time
        , d.recv_bytes
        , d.vip_type
        , d.anti_server
        , d.task_origin
        , d.ref_url
        , d.file_url
        , xl_urldecode(xl_urldecode(d.file_url)) as url
        , d.global_speed
        , d.download_strategy
        , d.token
        , d.error_bytes
        , d.index_extra_data
        , d.ts
        , d.jiasu_vip_speed
        , d.jiasu_super_speed
        , d.jiasu_smooth
        , d.jiasu_zero_speed
        , d.jiasu_group
        , d.all_bytes
        , d.origin_bytes
        , d.server_bytes
        , d.phub_bytes
        , d.phub_peer
        , d.tracker_bytes
        , d.tracker_peer
        , d.dcdn_bytes
        , d.dcdn_peer
        , d.pcdn_bytes
        , d.pcdn_peer
        , d.bonus_bytes
        , d.bonus_peer
        , d.phub_cdn_bytes
        , d.phub_dcdn_bytes
        , d.xphub_bytes
        , d.super_pcdn_bytes
        , d.super_pcdn_peer
        , d.phub_res_peer
        , d.phub_insert_peer
        , d.running_task_count_avg
        , d.running_user_task_count_avg
        , d.global_all_bytes
        , d.global_p2p_bytes
        , d.global_p2s_bytes
        , d.global_bonus_bytes
        , d.global_dcdn_bytes
        , d.global_origin_bytes
        , d.etag
        , d.query_all_hub_count
        , d.query_all_hub_result
        , d.global_speed_target_1
        , d.global_speed_target_64
        , d.first_insert_pcdn_peer_time
        , d.alloc_data_buffer_fail_count
        , d.global_speed_max_in_window
        , d.ending_span_time
        , d.is_netdisk_fetch_task
        , d.first_video_mode
        , d.player_mode
        , d.platform
        , d.action_type
        , if(hfk.hubgcid is not null, 1, 0) as is_hfk
    from
        dw_xlyun.dwd_xlyun_transfer_seqid_platform_dedup_d_inc as d
    left join (
        select
            hubgcid
        from
            dw_xlyun.dim_xlyun_transfer_gcid_forbidden_hfk_d_inc
        where
            ds = '${date}'
            and coalesce(hubgcid, '') <> ''
        group by
            hubgcid
    ) as hfk
    on
        d.hub_gcid = hfk.hubgcid
        and coalesce(d.hub_gcid, '') <> ''
    where
        d.ds = '${date}'
)

insert overwrite table dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc
select /*+ MAPJOIN(dim_pub1, dim_pub2) */
    joined.peer_id
    , joined.user_id
    , joined.guid
    , joined.parent_id
    , joined.seqid
    , joined.event_id
    , cast(joined.server_info as string) as server_info
    , joined.cmdid
    , joined.appid
    , joined.service_version
    , joined.product_version
    , joined.service_name
    , joined.extdata_head
    , joined.process_id
    , joined.ip
    , joined.attribute1
    , joined.attribute2
    , joined.cost1
    , joined.cost2
    , joined.cost3
    , joined.cost4
    , coalesce(joined.final_result, 'N/A') as final_result
    , joined.event_status
    , case
        when joined.mode = '0' then 'new'
        when joined.mode = '1' then 'continue'
        when joined.mode is null then 'N/A'
        else joined.mode
    end as mode
    , joined.file_name
    , joined.file_suffix
    , coalesce(dim_pub1.dim_value, 'N/A') as file_type_code
    , coalesce(dim_pub1.dim_value_desc, 'N/A') as file_type_name
    , joined.file_size
    , joined.extdata
    , joined.cdn_res_count
    , joined.dcdn_hub_res_num
    , joined.high_res_count
    , joined.error_code
    , coalesce(dim_pub2.dim_key, 'N/A') as fail_reason_code
    , coalesce(dim_pub2.dim_value, 'N/A') as fail_reason_name
    , joined.task_type
    , if(length(joined.hub_gcid) = 40, joined.hub_gcid, 'N/A') as hub_gcid
    , if(length(joined.real_gcid) = 40, joined.real_gcid, 'N/A') as real_gcid
    , joined.download_time
    , joined.recv_bytes
    , joined.vip_type
    , '' as is_vip
    , joined.anti_server
    , joined.is_hfk
    , joined.task_origin
    , '' as prov_id
    , '' as city_id
    , '' as sp_id
    , joined.ref_url
    , if(length(parse_url(joined.ref_url, 'HOST')) >= 1, parse_url(joined.ref_url, 'HOST'), 'unknown') as source_host
    , joined.url
    , cast(joined.global_speed as bigint) as global_speed
    , joined.download_strategy
    , joined.token
    , cast(joined.error_bytes as bigint) as error_bytes
    , joined.index_extra_data
    , joined.ts
    , joined.jiasu_vip_speed
    , joined.jiasu_super_speed
    , joined.jiasu_smooth
    , joined.jiasu_zero_speed
    , joined.jiasu_group
    , joined.all_bytes
    , joined.origin_bytes
    , joined.server_bytes
    , joined.phub_bytes
    , joined.phub_peer
    , joined.tracker_bytes
    , joined.tracker_peer
    , joined.dcdn_bytes
    , joined.dcdn_peer
    , joined.pcdn_bytes
    , joined.pcdn_peer
    , joined.bonus_bytes
    , joined.bonus_peer
    , joined.phub_cdn_bytes
    , joined.phub_dcdn_bytes
    , joined.xphub_bytes
    , joined.super_pcdn_bytes
    , joined.super_pcdn_peer
    , joined.phub_res_peer
    , joined.phub_insert_peer
    , joined.running_task_count_avg
    , joined.running_user_task_count_avg
    , joined.global_all_bytes
    , joined.global_p2p_bytes
    , joined.global_p2s_bytes
    , joined.global_bonus_bytes
    , joined.global_dcdn_bytes
    , joined.global_origin_bytes
    , joined.etag
    , joined.query_all_hub_count
    , nvl(joined.query_all_hub_result, 'N/A') as query_all_hub_result
    , coalesce(joined.global_speed_target_64, joined.global_speed_target_1, 0) as global_speed_target
    , joined.first_insert_pcdn_peer_time
    , joined.alloc_data_buffer_fail_count
    , joined.global_speed_max_in_window
    , joined.ending_span_time
    , joined.is_netdisk_fetch_task
    , joined.first_video_mode
    , joined.player_mode
    , split(ip_parser(joined.ip), ',')[0] as country_name
    , split(ip_parser(joined.ip), ',')[1] as prov_name
    , split(ip_parser(joined.ip), ',')[2] as city_name
    , split(ip_parser(joined.ip), ',')[3] as carrier_name
    , if(joined.platform = 'pc', joined.extdata['NetWorkType'], joined.extdata['NetworkType']) as network_type
    , case
        when joined.action_type = 'withdraw' then 0
        when joined.action_type = 'download'
            and joined.url like '%sandai%'
            and joined.url like '%backstage-file-ssl.a.88cdn.com/pc/upgrade/%'
            and joined.url like '%static-xl9-ssl.xunlei.com%'
            and joined.url like '%xlgameupdate%'
            and joined.url like '%admin.xl9.xunlei.com%'
            and joined.url like '%static-pc.xunlei.com%'
            and joined.url like '%xunleisetup%'
            and joined.url like '%xunlei.com%'
        then 1
        else 0
        end as flag_system
    , case
        when joined.task_type in ('1', '14', '4635') then 'p2sp'
        when joined.task_type in ('4636') then 'bt_main'
        when joined.task_type in ('3', '4637') then 'bt'
        when joined.task_type in ('4', '4638') then 'emule'
        when joined.task_type in ('4639') then 'magnet'
        when joined.task_type in ('12', '16') then 'hls'
        else 'other'
    end as task_type_name
     , case
            when joined.vip_type in ('2', 'normal') then '1'
            when joined.vip_type in ('3', 'platinum') then '3'
            when joined.vip_type in ('super', '5') then '5'
            else '0'
        end as vip_type_name
    , '${date}' as ds
    , joined.platform
    , joined.action_type
from
    joined
left join (
    select
        dim_key
        , dim_value
        , dim_value_desc
    from
        dw_xlyun.dim_pub_sundry_manual_full
    where
        dim_type = 'file_type'
) as dim_pub1
on
    dim_pub1.dim_key = joined.file_suffix
left join (
    select
        dim_key
        , dim_value
        , dim_value_desc
    from
        dw_xlyun.dim_pub_sundry_manual_full
    where
        dim_type = 'download_error_type'
) as dim_pub2
on
    dim_pub2.dim_key = joined.error_code
;

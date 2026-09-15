------------------------------------------------------------
--  FILE:    dws_xlyun_transfer_download_seqid_d_inc.sql
--  DESC:    传输库下载/取回分片粒度 DWS（测试）
--  UPSTREAM: dwd_xlyun_transfer_seqid_platform_d_inc
--            dim_xlyun_transfer_mp_gcid_info_d_inc
--  PARAM:   ds='${date}'
--  NOTE:    仅保留 platform in (pc/android/ios/mac/nas/harmony)，action_type in (download/withdraw)
--           过滤 BT_main、magnet，避免 BT 主/子任务重复统计及磁力链种子任务重复
--           采集侧改读 PRE 下游 DIM：dim_xlyun_transfer_mp_gcid_info_d_inc
------------------------------------------------------------

insert overwrite dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc
select
    download.seqid
    , download.parent_id as parentid
    , download.gcid
    , download.url as download_url
    , download.user_id
    , download.guid
    , download.peer_id as peerid
    , download.is_c_type
    , download.vip_type
    , coalesce(gcid.gcid_region, 'N/A') as server_room
    , download.carrier
    , download.province
    , download.global_speed_target
    , download.target_speed_range
    , coalesce(download.global_speed / 1024, 0) as global_speed
    , coalesce(download.global_speed_max_in_window / 1024, 0) as global_speed_max_in_window
    , coalesce(download.recv_bytes / 1024, 0) as recv_bytes
    , download.final_result
    , download.is_target_achieve
    , download.is_index
    , if(gcid.gcid is not null, '1', '0') as is_collect
    , download.is_token
    , download.is_query_hub
    , download.is_query_result
    , download.is_query_peer_slow
    , download.is_buffer_fail
    , download.is_ending_span_slow
    , download.seq_zero_speed
    , download.seq_fail
    , download.ts
    , download.download_time
    , download.event_status as eventstatus
    , download.mode
    , download.file_name
    , download.file_suffix
    , download.file_type_code
    , download.file_type_name
    , download.file_size
    , download.anti_server
    , download.is_hfk
    , download.error_code
    , download.fail_reason_code
    , download.fail_reason_name
    , download.real_gcid
    , download.ref_url as refurl
    , download.source_host
    , download.token
    , download.query_all_hub_count
    , download.query_all_hub_result
    , download.first_insert_pcdn_peer_time
    , download.alloc_data_buffer_fail_count
    , download.ending_span_time
    , download.task_type_name as task_type
    , download.download_strategy
    , coalesce(download.network_type, 'unknown') as network_type
    , case
        when download.seq_fail = '0' then '下载成功'
        when error_code in ('111151', '111152', '111153', '111154', '111155', '111156') then '资源封禁'
        when error_code in ('119238') then 'SSL证书校验失败'
        when error_code in ('111148', '111149') then '资源文件不存在'
        when error_code in ('9129', '111083', '111085', '111095', '111127', '111128') then '磁盘操作'
        when error_code in ('111179', '111180', '111181') then '纠错过多'
        when error_code in ('111136', '111176') then '长时间没收到数据0速'
        when error_code in ('114001', '114101') then 'eMule失败'
        else concat('未分类错误:', coalesce(error_code, ''))
        end as error_category
    , case
        when download.error_code in ('111151', '111152', '111153', '111154', '111155', '111156') then '封禁资源'
        when download.gcid is null or download.gcid = 'N/A' or length(download.gcid) <> 40 then '无资源无采集'
        when gcid.gcid is not null then '有采集有gcid'
        else '无采集有gcid'
        end as resource_type
    , download.service_version
    , download.product_version
    , '' as country_name
    , city_name as city
    , country_name as country
    , coalesce(download.origin_bytes, 0) as origin_bytes
    , coalesce(download.server_bytes, 0) as server_bytes
    , coalesce(download.tracker_bytes, 0) as tracker_bytes
    , coalesce(download.dcdn_bytes, 0) as dcdn_bytes
    , coalesce(download.pcdn_bytes, 0) as pcdn_bytes
    , coalesce(download.bonus_bytes, 0) as bonus_bytes
    , coalesce(download.all_bytes, 0) as all_bytes
    , download.phub_res_peer
    , download.task_origin
    , download.flag_system
    , parse_url(xl_urldecode(url),'QUERY', 'share_user_id') as share_user_id
    , coalesce(download.phub_bytes, 0) as phub_bytes
    , case
        when download.file_size >= 10485760 then 1
        else 0
        end as is_file_size_over_10mb
    , '${date}' as ds
    , download.platform
    , download.action_type
from (
    select
        seqid
        , parent_id
        , url
        , coalesce(hub_gcid, real_gcid)  as gcid
        , user_id
        , guid
        , peer_id
        , if(anti_server = '1' or cast(is_hfk as string) = '1', '1', '0') as is_c_type
        , vip_type_name as vip_type
        , carrier_name as carrier
        , prov_name    as province
        , global_speed_target
        , case
            when global_speed_target = 0 then '未上报'
            when global_speed_target > 0 and global_speed_target < 1024 * 0.5 then '(0M, 0.5M)'
            when global_speed_target >= 1024 * 0.5 and global_speed_target < 1024 then '[0.5M, 1M)'
            when global_speed_target >= 1024 and global_speed_target < 1024 * 2 then '[1M, 2M)'
            when global_speed_target >= 1024 * 2 and global_speed_target < 1024 * 3 then '[2M, 3M)'
            when global_speed_target >= 1024 * 3 and global_speed_target < 1024 * 4 then '[3M, 4M)'
            when global_speed_target >= 1024 * 4 and global_speed_target < 1024 * 5 then '[4M, 5M)'
            when global_speed_target >= 1024 * 5 and global_speed_target < 1024 * 6 then '[5M, 6M)'
            when global_speed_target >= 1024 * 6 and global_speed_target < 1024 * 7 then '[6M, 7M)'
            when global_speed_target >= 1024 * 7 and global_speed_target < 1024 * 8 then '[7M, 8M)'
            when global_speed_target >= 1024 * 8 and global_speed_target < 1024 * 9 then '[8M, 9M)'
            when global_speed_target >= 1024 * 9 and global_speed_target < 1024 * 10 then '[9M, 10M)'
            when global_speed_target >= 1024 * 10 and global_speed_target < 1024 * 20 then '[10M, 20M)'
            when global_speed_target >= 1024 * 20 and global_speed_target < 1024 * 30 then '[20M, 30M)'
            when global_speed_target >= 1024 * 30 and global_speed_target < 1024 * 40 then '[30M, 40M)'
            when global_speed_target >= 1024 * 40 and global_speed_target < 1024 * 50 then '[40M, 50M)'
            when global_speed_target >= 1024 * 50 then '50M及以上'
            else 'N/A'
        end as target_speed_range
        , global_speed
        , global_speed_max_in_window
        , recv_bytes
        , final_result
        , if(
            coalesce(global_speed_target, 0) <> 0
            and coalesce(global_speed / 1024, 0) > coalesce(global_speed_target, 0)
            , '1'
            , '0'
        ) as is_target_achieve
        , if(hub_gcid <> 'N/A', '1', '0') as is_index
        , if(token is not null, '1', '0') as is_token
        , if(cast(query_all_hub_count as bigint) > 0, '1', '0') as is_query_hub
        , if(
            (platform = 'pc' and query_all_hub_result = 'success')
            or (platform <> 'pc' and coalesce(query_all_hub_result, '0') <> '0')
            , '1'
            , '0'
        ) as is_query_result
        , if(first_insert_pcdn_peer_time > download_time * 1000 * 0.2, '1', '0') as is_query_peer_slow
        , if(alloc_data_buffer_fail_count > 0, '1', '0') as is_buffer_fail
        , if(ending_span_time > 10000 or ending_span_time > download_time * 100, '1', '0') as is_ending_span_slow
        , if(download_time > 10 and recv_bytes = 0, '1', '0') as seq_zero_speed
        , if(final_result in ('failure', 'fail'), '1', '0') as seq_fail
        , ts
        , download_time
        , event_status
        , mode
        , file_name
        , file_suffix
        , file_type_code
        , file_type_name
        , file_size
        , anti_server
        , cast(is_hfk as string) as is_hfk
        , error_code
        , fail_reason_code
        , fail_reason_name
        , real_gcid
        , ref_url
        , source_host
        , token
        , query_all_hub_count
        , query_all_hub_result
        , first_insert_pcdn_peer_time
        , alloc_data_buffer_fail_count
        , ending_span_time
        , task_type
        , task_type_name
        , download_strategy
        , network_type
        , service_version
        , product_version
        , platform
        , action_type
        , country_name
        , city_name
        , origin_bytes
        , server_bytes
        , tracker_bytes
        , dcdn_bytes
        , pcdn_bytes
        , bonus_bytes
        , all_bytes
        , phub_res_peer
        , task_origin
        , flag_system
        , phub_bytes
    from
        dw_xlyun.dwd_xlyun_transfer_seqid_platform_d_inc
    where
        ds = '${date}'
        and platform in ('pc', 'android', 'ios', 'mac', 'nas', 'harmony')
        and action_type in ('download', 'withdraw')
        and task_type_name not in ('bt_main', 'magnet') -- bt主任务和子任务统计重复，磁力链即bt种子的下载任务，故过滤
        and coalesce(task_origin, '')  <> 'background'  --剔除自有后台下载任务
        and coalesce(extdata['isvideopreloadtask'], '') <> '1' -- 剔除预部署 decache
        --过滤异常值，小于10T
        and nvl(file_size,0)<10995116277760
        and nvl(all_bytes,0)<10995116277760
        and nvl(origin_bytes,0)<10995116277760
        and nvl(phub_bytes,0)<10995116277760
        and nvl(tracker_bytes,0)<10995116277760
        and nvl(dcdn_bytes,0)<10995116277760
        --过滤异常版本号，规则：版本号都为数字，且最少包含一个 ’.' 符号
        and instr(product_version, '.') > 1
        and instr(service_version, '.') > 1
        and ((platform='pc' and service_name in ('pc.thunderX', 'pc.NetDisk_N')) or platform in ('android', 'ios', 'mac', 'nas', 'harmony')) --过滤pc非下载的产品
        and task_type_name in ('p2sp','bt','emule','hls')
) as download
left join (
    select
        gcid
        , max(section) as gcid_region
        , max(unix_timestamp(dt_committed, 'yyyy-MM-dd HH:mm:ss')) as caiji_ts
    from
        dw_xlyun.dim_xlyun_transfer_mp_gcid_info_d_inc
    where
        ds = '${date}'
    group by
        gcid
) as gcid
on
    gcid.gcid = download.gcid
;

-- create table dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc (
--     seqid                          string   comment '分片id'
--     , parentid                     string   comment '任务id'
--     , gcid                         string   comment '资源id'
--     , download_url                 string   comment '下载url'
--     , user_id                      string   comment '用户id'
--     , guid                         string   comment '设备id'
--     , peerid                       string   comment '传输库id'
--     , is_c_type                    string   comment '【资源属性】是否c类，1:是，0：否'
--     , vip_type                     string   comment '【用户属性】会员身份'
--     , server_room                  string   comment '【资源属性】机房'
--     , carrier                      string   comment '运营商，通过ip解析得到'
--     , Province                     string   comment '省份，通过ip解析得到'
--     , global_speed_target          bigint   comment '【策略】IDC目标配速，单位：kb'
--     , target_speed_range           string   comment '目标配速区间'
--     , global_speed                 bigint   comment '全局速度，中台上报的子任务速度，单位：kb'
--     , global_speed_max_in_window   bigint   comment '边下边测-最大测速，单位：kb'
--     , recv_bytes                   bigint   comment '本次接收总字节数,单位：kb'
--     , final_result                 string   comment '下载结果'
--     , is_target_achieve            string   comment '【分片属性】是否达标，1:是，0：否'
--     , is_index                     string   comment '【资源属性】是否索引，1:是，0：否；【备注】资源无索引，或查索引失败，gcid为空'
--     , is_collect                   string   comment '【资源属性】是否采集，1:是，0：否'
--     , is_token                     string   comment '【分片属性】是否有token，1:是，0：否'
--     , is_query_hub                 string   comment '【分片属性】是否查种，1:是，0：否；【备注】分片最后上报时有token，但没有查peer'
--     , is_query_result              string   comment '【分片属性】是否回包，1:是，0：否；【备注】有发起查peer的动作，但最终传输库没收到结果'
--     , is_query_peer_slow           string   comment '【分片属性】是否查peer慢，1:是，0：否；【备注】查peer耗时久，第一次拿到peer的时间大于总时长的20%'
--     , is_buffer_fail               string   comment '【分片属性】是否磁盘慢，内存问题限速，1:是，0：否'
--     , is_ending_span_slow          string   comment '【分片属性】是否写磁盘慢，1:是，0：否；【备注】因为写入磁盘速度过慢，任务占用内存超过警戒值，传输库会进行速度限制'
--     , seq_zero_speed               string   comment '【分片属性】分片零速, 1:是，0：否；'
--     , seq_fail                     string   comment '【分片属性】分片失败, 1:是，0：否；'
--     , ts                           string   comment '任务创建时间'
--     )
-- comment 'dws_迅雷云_传输库_下载|取回_分片粒度'
-- partitioned by (
--     ds string comment '日期分区',
--     platform string comment '端，pc，andriod，ios，mac，nas，鸿蒙',
--     action_type string comment '行为，下载/取回'
-- )
-- stored as parquet;

-- 添加日期：20260604，补充字段
-- alter table dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc add columns(
--     download_time bigint comment '分片下载时长'
--     , eventstatus string comment '任务状态，开始、心跳、结束'
--     , mode string comment '是否为续传，pc：1-续传 0-新建'
--     , file_name string comment '文件名'
--     , file_suffix string comment '文件名后缀'
--     , file_type_code string comment '文件类型'
--     , file_type_name string comment '文件类型_中文名'
--     , file_size bigint comment '文件大小（字节）'
--     , anti_server string comment '会员侧上报的黄反标记 1:黄反，0:非黄反'
--     , is_hfk string comment '关联黄反库，1：是，0：否'
--     , error_code string comment '下载失败原因原始code'
--     , fail_reason_code string comment '下载失败原因code'
--     , fail_reason_name string comment '下载失败原因中文名'
--     , real_gcid string comment '本地计算的gcid，非首次采集时=hubgcid'
--     , refurl string comment '下载访问页url'
--     , source_host string comment '来源网站'
--     , token STRING COMMENT 'token'
--     , query_all_hub_count STRING COMMENT '是否查种，是否有查询加速节点，0表示未查种'
--     , query_all_hub_result STRING COMMENT '查询加速节点结果，是否有回包'
--     , first_insert_pcdn_peer_time BIGINT COMMENT '查peer耗时，移动端无'
--     , alloc_data_buffer_fail_count BIGINT COMMENT '磁盘慢，内存问题限速次数'
--     , ending_span_time BIGINT COMMENT '写入磁盘耗时'
--     , task_type string comment '任务类型， tasktype (安卓,pc) (''1'',''4635'')-p2sp (''3'',''4637'')-bt  (''4'',''4638'')-emule任务'
--     , download_strategy bigint comment '下载策略'
--     , network_type string comment '网络类型，用户下载时所用的网络环境。PC端取值：，0：断网，1：无线，2：有线，3：未知；移动端取值： ，0：断网，1：手机网络，2：2G，3：3G，4：4G，5：5G，9：wifi，1：有线，1：未知'
-- )

-- 添加日期：20260709、20260710，补充字段
-- alter table dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc add columns(
--     error_category string comment '失败原因类型'
--     , resource_type string comment '资源类型'
--     , service_version string comment '客户端版本'
--     , product_version string comment 'SDK版本'
-- )
-- alter table dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc add columns(
--     country_name string comment '国家；客户端ip解析'
--     , city string comment '城市'
--     , country string comment '国家'
-- );

-- 添加日期：20260731，流量拆分字段（字节，透传自 DWD）
-- alter table dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc add columns(
-- origin_bytes bigint comment '原始资源下载字节数'
-- , server_bytes bigint comment '镜像资源下载字节数'
-- , tracker_bytes bigint comment 'tracker下载字节数'
-- , dcdn_bytes bigint comment 'dcdn下载字节数'
-- , pcdn_bytes bigint comment 'pcdn下载字节数'
-- , bonus_bytes bigint comment 'bonus下载字节数'
-- , all_bytes bigint comment '总下载字节数'
-- , phub_res_peer bigint comment 'phub资源peer数'
-- , task_origin string comment '任务来源'
-- , flag_system bigint comment '是否迅雷自有插件类任务，0否1是'
-- , share_user_id string comment '达人id'
-- );

-- 添加日期：20260805，补漏 phub_bytes + 文件大小标记
-- alter table dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc add columns(
--     phub_bytes bigint comment 'phub下载字节数'
--     , is_file_size_over_10mb bigint comment '文件大小是否>=10MB，1:是，0:否'
-- );

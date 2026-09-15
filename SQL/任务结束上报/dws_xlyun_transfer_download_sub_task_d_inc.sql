------------------------------------------------------------
--  FILE:    dws_xlyun_transfer_download_sub_task_d_inc.sql
--  DESC:    传输库下载/取回子任务粒度 DWS
--  UPSTREAM: dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc
--  PARAM:   ds='${date}'
--  GRAIN:   子任务 = peerid + parentid + download_url + platform + action_type
--  NOTE:    按分组键聚合；属性 max；状态 max_by(ts)；
--           global_speed 对非0非null取 avg；
--           seq_zero_speed：至少1个分片 download_time>10 且全部分片 recv_bytes=0 才记零速；
--           流量字段对分片 sum
------------------------------------------------------------

insert overwrite table dw_xlyun.dws_xlyun_transfer_download_sub_task_d_inc
select
    max_by(seqid, ts) as seqid
    , coalesce(parentid, 'N/A') as parentid
    , max(gcid) as gcid
    , coalesce(download_url, 'N/A') as download_url
    , max(user_id) as user_id
    , max(guid) as guid
    , coalesce(peerid, 'N/A') as peerid
    , max(is_c_type) as is_c_type
    , max(vip_type) as vip_type
    , max(server_room) as server_room
    , max_by(carrier, ts) as carrier
    , max_by(province, ts) as province
    , max_by(global_speed_target, ts) as global_speed_target
    , cast(null as string) as target_speed_range
    , avg(if(global_speed is not null and global_speed <> 0, global_speed, null)) as global_speed
    , max(global_speed_max_in_window) as global_speed_max_in_window
    , sum(recv_bytes) as recv_bytes
    , max_by(final_result, ts) as final_result
    , max_by(is_target_achieve, ts) as is_target_achieve
    , max_by(is_index, ts) as is_index
    , max_by(is_collect, ts) as is_collect
    , max_by(is_token, ts) as is_token
    , max_by(is_query_hub, ts) as is_query_hub
    , max_by(is_query_result, ts) as is_query_result
    , max_by(is_query_peer_slow, ts) as is_query_peer_slow
    , max_by(is_buffer_fail, ts) as is_buffer_fail
    , max_by(is_ending_span_slow, ts) as is_ending_span_slow
    , if( max(seq_zero_speed) = '1' and sum(recv_bytes)=0 , '1' , '0' ) as seq_zero_speed
    , max_by(seq_fail, ts) as seq_fail
    , max(ts) as ts
    , sum(download_time) as download_time
    , max_by(eventstatus, ts) as eventstatus
    , min_by(mode, ts) as mode
    , max(file_name) as file_name
    , max_by(file_suffix, ts) as file_suffix
    , max_by(file_type_code, ts) as file_type_code
    , max_by(file_type_name, ts) as file_type_name
    , max(file_size) as file_size
    , max_by(anti_server, ts) as anti_server
    , max_by(is_hfk, ts) as is_hfk
    , max_by(error_code, ts) as error_code
    , max_by(fail_reason_code, ts) as fail_reason_code
    , max_by(fail_reason_name, ts) as fail_reason_name
    , max_by(real_gcid, ts) as real_gcid
    , max_by(refurl, ts) as refurl
    , max_by(source_host, ts) as source_host
    , max_by(token, ts) as token
    , max_by(query_all_hub_count, ts) as query_all_hub_count
    , max_by(query_all_hub_result, ts) as query_all_hub_result
    , max_by(first_insert_pcdn_peer_time, ts) as first_insert_pcdn_peer_time
    , sum(alloc_data_buffer_fail_count) as alloc_data_buffer_fail_count
    , sum(ending_span_time) as ending_span_time
    , max_by(task_type, ts) as task_type
    , max_by(download_strategy, ts) as download_strategy
    , max(network_type) as network_type
    , max_by(error_category, ts) as error_category
    , max_by(resource_type, ts) as resource_type
    , max_by(service_version, ts) as service_version
    , max_by(product_version, ts) as product_version
    , max_by(country, ts) as country
    , max_by(city, ts) as city
    , sum(origin_bytes) as origin_bytes
    , sum(server_bytes) as server_bytes
    , sum(tracker_bytes) as tracker_bytes
    , sum(dcdn_bytes) as dcdn_bytes
    , sum(pcdn_bytes) as pcdn_bytes
    , sum(bonus_bytes) as bonus_bytes
    , sum(all_bytes) as all_bytes
    , max(phub_res_peer) as phub_res_peer
    , max(task_origin) as task_origin
    , max(flag_system) as flag_system
    , max(share_user_id) as share_user_id
    , sum(phub_bytes) as phub_bytes
    , max(is_file_size_over_10mb) as is_file_size_over_10mb
    , '${date}' as ds
    , platform
    , action_type
from
    dw_xlyun.dws_xlyun_transfer_download_seqid_d_inc
where
    ds = '${date}'
group by
    coalesce(peerid, 'N/A')
    , coalesce(parentid, 'N/A')
    , coalesce(download_url, 'N/A')
    , platform
    , action_type
;


-- create table dw_xlyun.dws_xlyun_transfer_download_sub_task_d_inc (
--     seqid                          string   comment '末条分片id（子任务最终状态对应分片）'
--     , parentid                     string   comment '主任务id'
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
--     , target_speed_range           string   comment '目标配速区间（置空）'
--     , global_speed                 decimal(38,4)   comment '全局速度均值（剔除0和null），单位：kb'
--     , global_speed_max_in_window   bigint   comment '边下边测-最大测速，单位：kb'
--     , recv_bytes                   bigint   comment '接收总字节数合计,单位：kb'
--     , final_result                 string   comment '下载结果（末条分片）'
--     , is_target_achieve            string   comment '【子任务最终状态】是否达标，1:是，0：否'
--     , is_index                     string   comment '【资源属性】是否索引，1:是，0：否'
--     , is_collect                   string   comment '【资源属性】是否采集，1:是，0：否'
--     , is_token                     string   comment '【子任务最终状态】是否有token，1:是，0：否'
--     , is_query_hub                 string   comment '【子任务最终状态】是否查种，1:是，0：否'
--     , is_query_result              string   comment '【子任务最终状态】是否回包，1:是，0：否'
--     , is_query_peer_slow           string   comment '【子任务最终状态】是否查peer慢，1:是，0：否'
--     , is_buffer_fail               string   comment '【子任务最终状态】是否磁盘慢/内存限速，1:是，0：否'
--     , is_ending_span_slow          string   comment '【子任务最终状态】是否写磁盘慢，1:是，0：否'
--     , seq_zero_speed               string   comment '【子任务】零速：至少1个分片零速且全部分片recv_bytes=0则为1，否则0'
--     , seq_fail                     string   comment '【子任务最终状态】失败，1:是，0：否'
--     , ts                           string   comment '末条分片创建时间'
--     , download_time                bigint   comment '分片下载时长合计'
--     , eventstatus                  string   comment '任务状态，开始、心跳、结束'
--     , mode                         string   comment '是否为续传，pc：1-续传 0-新建'
--     , file_name                    string   comment '文件名'
--     , file_suffix                  string   comment '文件名后缀'
--     , file_type_code               string   comment '文件类型'
--     , file_type_name               string   comment '文件类型_中文名'
--     , file_size                    bigint   comment '文件大小（字节）'
--     , anti_server                  string   comment '会员侧上报的黄反标记 1:黄反，0:非黄反'
--     , is_hfk                       string   comment '关联黄反库，1：是，0：否'
--     , error_code                   string   comment '下载失败原因原始code'
--     , fail_reason_code             string   comment '下载失败原因code'
--     , fail_reason_name             string   comment '下载失败原因中文名'
--     , real_gcid                    string   comment '本地计算的gcid'
--     , refurl                       string   comment '下载访问页url'
--     , source_host                  string   comment '来源网站'
--     , token                        string   comment 'token'
--     , query_all_hub_count          string   comment '是否查种'
--     , query_all_hub_result         string   comment '查询加速节点结果'
--     , first_insert_pcdn_peer_time  bigint   comment '查peer耗时'
--     , alloc_data_buffer_fail_count bigint   comment '磁盘慢，内存问题限速次数'
--     , ending_span_time             bigint   comment '写入磁盘耗时'
--     , task_type                    string   comment '任务类型'
--     , download_strategy            bigint   comment '下载策略'
--     , network_type                 string   comment '网络类型'
--     , error_category               string   comment '失败原因类型'
--     , resource_type                string   comment '资源类型'
--     , service_version              string   comment '客户端版本'
--     , product_version              string   comment 'SDK版本'
--     , country                      string   comment '国家；客户端ip解析'
--     , city                         string   comment '城市'
--     , origin_bytes                 bigint   comment '原始资源下载字节数合计'
--     , server_bytes                 bigint   comment '镜像资源下载字节数合计'
--     , tracker_bytes                bigint   comment 'tracker下载字节数合计'
--     , dcdn_bytes                   bigint   comment 'dcdn下载字节数合计'
--     , pcdn_bytes                   bigint   comment 'pcdn下载字节数合计'
--     , bonus_bytes                  bigint   comment 'bonus下载字节数合计'
--     , all_bytes                    bigint   comment '总下载字节数合计'
--     , phub_res_peer                bigint   comment 'phub资源peer数'
--     , task_origin                  string   comment '任务来源'
--     , flag_system                  bigint   comment '是否迅雷自有插件类任务，0否1是'
--     , share_user_id                string   comment '达人id'
-- )
-- comment 'dws_迅雷云_传输库_下载|取回_子任务粒度'
-- partitioned by (
--     ds string comment '日期分区',
--     platform string comment '端，pc，android，ios，mac，nas，harmony',
--     action_type string comment '行为，下载/取回'
-- )
-- stored as parquet;

-- 添加日期：20260805，对齐分片表新增字段
-- alter table dw_xlyun.dws_xlyun_transfer_download_sub_task_d_inc add columns(
--     phub_bytes bigint comment 'phub下载字节数合计'
--     , is_file_size_over_10mb bigint comment '文件大小是否>=10MB，1:是，0:否'
-- );
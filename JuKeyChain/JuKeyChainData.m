//
//  PFBKeyChainItem.m
//  MTSkinPublic
//
//  Created by Juvid on 2019/1/4.
//  Copyright © 2019 Juvid(zhutianwei). All rights reserved.
//

#import "JuKeyChainData.h"
#define jDelimiter @"-|-"

@implementation JuKeyChainData

+(BOOL)shSetObject:(nullable id)object forKey:(NSString *)key{
    NSData *data=nil;
    if ([object isKindOfClass:[NSString class]]) {
        data=[object dataUsingEncoding:NSUTF8StringEncoding];
    }else if ([object isKindOfClass:[NSDictionary class]]){
        NSDictionary *dic=object;
        NSString *strValue=nil;
        NSMutableArray * keysAndValues = [NSMutableArray arrayWithArray:dic.allKeys];
        [keysAndValues addObjectsFromArray:dic.allValues];
        if (keysAndValues.count>0) {
            strValue=[keysAndValues componentsJoinedByString:jDelimiter];
        }
        data=[strValue dataUsingEncoding:NSUTF8StringEncoding];
    }
    return [self shSetData:data forService:key account:nil accessGroup:nil];
}

+(id)shObjectForKey:(NSString *)key{
    NSData *data=[self shGetDataForKey:key account:nil accessGroup:nil];
    if (!data) {
        return nil;
    }
    NSString *strData=[[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    if ([strData containsString:jDelimiter]) {
        NSArray *keysAndValues = [NSArray arrayWithArray:[strData componentsSeparatedByString:jDelimiter]];
        if (keysAndValues.count>0&&keysAndValues.count%2 !=0) {
            return nil;
        }
        NSUInteger half = keysAndValues.count / 2;
        NSRange keys = NSMakeRange(0, half);
        NSRange values = NSMakeRange(half, half);
        NSDictionary *dicValue=[NSDictionary dictionaryWithObjects:[keysAndValues subarrayWithRange:values]
                                                           forKeys:[keysAndValues subarrayWithRange:keys]];
        return dicValue;
    }else{
        return strData;
    }
}
/**
 钥匙串存储

 @param value 数据
 @param serviceName 关键key
 @return 是否成功
 */
+(BOOL)shSetValue:(NSString *)value
       forService:(NSString *)serviceName
          account:(NSString *)account
      accessGroup:(NSString *)accessGroup{

    return  [self shSetData:[value dataUsingEncoding:NSUTF8StringEncoding] forService:serviceName account:account accessGroup:accessGroup];
}

/**
 钥匙串读取

 @param serviceName 关键key
 @return 数据
 */
+(id)shObjectForService:(NSString *)serviceName
                account:(NSString *)account
            accessGroup:(NSString *)accessGroup{
    NSData *data=[self shGetDataForKey:serviceName account:account accessGroup:accessGroup];
    if (!data) {
        return nil;
    }
    NSString *strData=[[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
    return strData;
}

+(BOOL)shSetData:(NSData *)data
      forService:(NSString *)serviceName
         account:(NSString *)account
     accessGroup:(NSString *)accessGroup{

    OSStatus status = -1;
    NSMutableDictionary * searchQuery = [self query];

    if (serviceName) {
        [searchQuery setObject:[self hierarchicalKey:serviceName groupKey:accessGroup] forKey:(__bridge id)kSecAttrService];
    }
    if (account) {
        [searchQuery setObject:account forKey:(__bridge id)kSecAttrAccount];
    }
//    if (accessGroup) {
        [searchQuery setObject:[self keychainGroupName:accessGroup] forKey:(__bridge id)kSecAttrAccessGroup];
//    }

    status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, nil);
    if (!data) {
        if (status == errSecSuccess) {
            status=SecItemDelete((__bridge CFDictionaryRef)searchQuery);
        }
        return (status == errSecSuccess);
    }

    NSMutableDictionary *query = nil;

    if (status == errSecSuccess) {//item already exists, update it!
        query = [[NSMutableDictionary alloc]init];
        [query setObject:data forKey:(__bridge id)kSecValueData];
#if __IPHONE_4_0 && TARGET_OS_IPHONE
        CFTypeRef accessibilityType = [JuKeyChainData accessibilityType];
        if (accessibilityType) {
            [query setObject:(__bridge id)accessibilityType forKey:(__bridge id)kSecAttrAccessible];
        }
#endif
        status = SecItemUpdate((__bridge CFDictionaryRef)(searchQuery), (__bridge CFDictionaryRef)(query));
    }else if(status == errSecItemNotFound){//item not found, create it!
        query = [NSMutableDictionary dictionaryWithDictionary:searchQuery];
        [query setObject:data forKey:(__bridge id)kSecValueData];
#if __IPHONE_4_0 && TARGET_OS_IPHONE
        CFTypeRef accessibilityType = [JuKeyChainData accessibilityType];
        if (accessibilityType) {
            [query setObject:(__bridge id)accessibilityType forKey:(__bridge id)kSecAttrAccessible];
        }
#endif
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
    if (status != errSecSuccess ) {
        NSLog(@"失败了哦");
    }
    return (status == errSecSuccess);
}

+(NSData *)shGetDataForKey:(NSString *)serviceName
                   account:(NSString *)account
               accessGroup:(NSString *)accessGroup{
    NSMutableDictionary *query = [self query];
    /// <多个key用其中一个即可 kSecAttrGeneric kSecAttrService kSecAttrAccount
    if (serviceName) {
        [query setObject:[self hierarchicalKey:serviceName groupKey:accessGroup] forKey:(__bridge id)kSecAttrService];
    }
    if (account) {
         [query setObject:account forKey:(__bridge id)kSecAttrAccount];
    }
    if (accessGroup) {
        [query setObject:[self keychainGroupName:accessGroup] forKey:(__bridge id)kSecAttrAccessGroup];
    }
    //    [query setObject:@"juvid" forKey:(__bridge id)kSecAttrAccount];
    [query setObject: (__bridge id) kCFBooleanTrue  forKey: (__bridge id) kSecReturnData];
    //    [query setObject:(__bridge id) kCFBooleanTrue forKey:(__bridge id)kSecReturnAttributes];
    //    [query setObject:(__bridge id)kSecMatchLimitAll forKey:(__bridge id)kSecMatchLimit];
#if __IPHONE_4_0 && TARGET_OS_IPHONE
    CFTypeRef accessibilityType = [JuKeyChainData accessibilityType];
    if (accessibilityType) {
        [query setObject:(__bridge id)accessibilityType forKey:(__bridge id)kSecAttrAccessible];
    }
#endif

    CFTypeRef refData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &refData);
    if (status != errSecSuccess ) {
        return nil;
    }
    return (__bridge_transfer NSData *)refData;
}

+ (NSMutableDictionary *)query {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    [dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    return dictionary;
}
+ (CFTypeRef)accessibilityType {
    return kSecAttrAccessibleWhenUnlocked;
}

+(NSString *)hierarchicalKey:(NSString *)key groupKey:(NSString *)groupKey{
    NSString *identifier = [self getServiceID:groupKey];
    return [identifier stringByAppendingFormat:@".%@", key];
}

+(NSString *)getServiceID:(NSString *)key{
    if (!key) {
        key = [[[NSBundle mainBundle] infoDictionary]objectForKey:(NSString*)kCFBundleIdentifierKey];
    }
    return key;
}

+(NSString *)keychainGroupName:(NSString *)key {
    static NSString *kBundleSeedID = nil;
    if (!kBundleSeedID) {
        kBundleSeedID = [self teamID];
    }
    NSString *groupName = [kBundleSeedID stringByAppendingString:@"."];
    groupName = [groupName stringByAppendingString:[self getServiceID:key]];
    return groupName;
}

+ (NSString*)teamID {
    NSDictionary*query = [NSDictionary dictionaryWithObjectsAndKeys:
                          (__bridge NSString *)kSecClassGenericPassword,kSecClass,
                          (id)kCFBooleanTrue,kSecReturnAttributes,
                          nil];

    CFDictionaryRef result =nil;

    OSStatus status =SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef*)&result);

    if(status ==errSecItemNotFound)

        status =SecItemAdd((CFDictionaryRef)query, (CFTypeRef*)&result);

    if(status !=errSecSuccess)

        return nil;

    NSString*accessGroup = [(__bridge NSDictionary*)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];

    NSArray*components = [accessGroup componentsSeparatedByString:@"."];

    NSString*bundleSeedID = [[components objectEnumerator]nextObject];

    CFRelease(result);

    return bundleSeedID;
}
/**查询钥匙串s所有**/
+(NSArray *)shGetAllKeyChainData {
    NSDictionary*query = [NSDictionary dictionaryWithObjectsAndKeys:
                          (__bridge NSString *)kSecClassGenericPassword,kSecClass,
                          (id)kSecMatchLimitAll,kSecMatchLimit,
                          (id)kCFBooleanTrue,kSecReturnData,
                          (id)kCFBooleanTrue,kSecReturnAttributes,
                          nil];
    CFDictionaryRef result =nil;

    OSStatus status =SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef*)&result);

    if(status !=errSecSuccess)

        return nil;

    return  (__bridge_transfer NSArray *)result;
}

@end

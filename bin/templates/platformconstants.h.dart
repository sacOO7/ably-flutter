String $(c) {
  return '''
@import Foundation;

typedef NS_ENUM(UInt8, _Value) {
  ${c['types'].map((_) => '${_['name']}CodecType = ${_['value']},').join('\n  ')}
};


@interface AblyPlatformMethod : NSObject
${c['methods'].map((_) => 'extern NSString *const AblyPlatformMethod_${_['name']};').join('\n')}
@end

${c['objects'].map((_) {
    return '''
@interface Tx${_['name']} : NSObject
${_['properties'].map((name) => 'extern NSString *const Tx${_['name']}_${name};').join('\n')}
@end
''';
  }).join('\n')}''';
}

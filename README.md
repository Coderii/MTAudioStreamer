# MTAudioStreamer

> 使用demo前特别注意。因为我的音乐文件链接是挂在七牛服务器上的，有时个别url会失效，导致demo个别音乐文件演示不出效果。

> 单个音乐详细演示的请将故事板中的initial viewController设置为viewController，如果需要演示多个音乐的效果，请将initial viewController设置为MTNavigationController。

> 一个audioFile只能初始化一次MusicFeature这样才能保证判断精确是否已经下载过和播放过

### 简介
	
- MTAudioStreamer是基于DOUAudioStreamer进行修改，在原框架上进行一些优化的操作。具体的功能如下。

#### 主要功能
- 点击播放功能，同一首音乐再点击下载，直接从播放缓存的进度开始继续下载

- 点击下载功能，同一首音乐再点击播放，播放的缓存进度直接从已经下载的进度开始缓存

- 支持断点续传，当音乐下载一半关闭后台，只要目录缓存文件存在，不需要多余的流浪重新下载

- 支持队列管理，设置最大并发数，可以限制一次能下载的音乐数量 

- 不管缓存或者下载完成后直接保存为本地文件

### 使用说明
#### 环境要求
* iOS版本要求: >= 7.0

#### 接入步骤
* 在原来的框架上修改，需要直接把我修改后的整个源码导入到项目中，需要自己设计队列管理的则只需要直接导入MTMusicFeature.h文件即可，然后在自己的队列中选择需要的方法。

	* 需要自己继承DOUAudioFile协议初始化model

	    	NSURL *url = [NSURL URLWithString:@" "];
			Track *track = [[Track alloc] init];
    		track.audioFileURL = url;
    		
    * 初始化MTMusicFeature

	    	self.musicFeature = [[MTMusicFeature alloc] initMusicFeatureWithAudioFile:track];
	    	
	* 开始音乐播放功能

			 [self.musicFeature startWithType:MTMusicFeatureTypePlay];
			 
	* 播放缓存进度反馈

			[self.musicFeature setPlayCacheProgress:^(double progress) {
				// 在这里可以操作进度条显示
	        }];
	 	
	* 开始音乐下载功能

			 [self.musicFeature startWithType:MTMusicFeatureTypeDownload];
			 
	* 下载进度反馈

	        [self.musicFeature setDownloadProgress:^(double progress) {
	        	// 在这里可以操作进度条显示
    	    }];
    	    
   	* 判断当前请求的URL是否在本地存在文件（下载或者缓存完成过）

		    if (self.musicFeature.localFileExist) {
		    	// 如果本地存在直接设置需要的进度条显示100%
		    	self.downloadProgressView.progress = 1.0f;
        	}
        	
* 如果使用我封装的队列。则直接导入MTOperationQueueManager.h文件。如果使用该队列管理。
> 需要注意的是，定义model文件的时候，需要继承MTDownLoadFileProtocol协议。

	* 初始化如下

			 @interface Track : NSObject <DOUAudioFile, MTDownLoadFileProtocol>
			 
	* 需要设置一个audiofile对应的一个musicFeatur，可以这样设置

			[_musicFeatureModelDict setObject:self.musicFeature forKey:[track audioFileURL].absoluteString];
			
	* 将下载放入队列管理，传入model和model对应的一个musicFeature

			[[MTMusicOperationManager sharedManager] startDownloadWithMusicModel:track
                                                            musicFeature:[_musicFeatureModelDict objectForKey:[track audioFileURL].absoluteString]];
			
	* 反馈当前队列中下载的进度

			[track.operation setProgressFeadBackBlock:^(double progress) {
				// 进度条使用
			}];
			
	* 点击播放添加播放进队列，始终保持播放的操作优先级最高

		    [[MTMusicOperationManager sharedManager] startPlayOperation:invocationOperation newDownloadProgress:^(double progress, id<MTDownLoadFileProtocol> model) { 
		    		//点击播放后返回新的缓存进度和之前下载过的model。可以用于操作更新进度条。
		    }];
		
### 主要的几个文件介绍

#### MTAudioHTTPRequest.h
- 主要的网络请求库，实现了断点续传的功能。替换掉了原来DOUAudioStreamer中的基于CFNetwork写的网络库，实现了原来DOUSimpleHTTPRequest有的方法。并在此基础上添加的断点续传功能。



#### MTConstant.h

* 几个库需要的共同变量或者属性

#### MTAudioDownloadProvider.h
- 从播放其中抽取出来用来下载的接口文件（缓存）

	- 传入AudioFile初始化MTAudioDownloadProvider
			
			self.downloadProvider = [[MTAudioDownloadProvider alloc] initAudioDownloadProviderWithAudioFile:_audioFile];

	- 开始下载

			[self.downloadProvider start];
			
	- 暂停下载

			[self.streamer pause];
			
	- 停止下载

			[self.streamer cancel];
			
	- 其他接口
	
			MTAudioDownloadProviderProgress //下载进度回调Block
			MTAudioDownloadProviderCompleted //下载完成的回调Block
			
#### MTMusicFeature.h
- 主要的封装接口，在这个接口内处理播放和下载操作的逻辑。完成主要的业务逻辑功能。根据MTMusicFeatureType枚举值选择当前是播放还是下载功能。

#### NSString+MTSH256Path.h
- NSString的分类，主要用于获取文件夹路径，以及用SH256数字签名得到文件名的一些函数。

### 其他问题
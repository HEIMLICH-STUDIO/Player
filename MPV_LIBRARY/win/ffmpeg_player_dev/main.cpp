#include <iostream>
#include <string>
#include <memory>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/avutil.h>
#include <libswscale/swscale.h>
}

class ProResPlayer {
private:
    AVFormatContext* formatContext = nullptr;
    AVCodecContext* codecContext = nullptr;
    const AVCodec* codec = nullptr;
    AVFrame* frame = nullptr;
    AVPacket* packet = nullptr;
    SwsContext* swsContext = nullptr;
    int videoStreamIndex = -1;

public:
    ProResPlayer() {
        // FFmpeg 초기화
        av_log_set_level(AV_LOG_INFO);
        std::cout << "=== ProRes Player 초기화 ===" << std::endl;
        std::cout << "FFmpeg 버전: " << av_version_info() << std::endl;
    }

    ~ProResPlayer() {
        cleanup();
    }

    bool openFile(const std::string& filename) {
        std::cout << "\n파일 열기: " << filename << std::endl;

        // 포맷 컨텍스트 할당
        formatContext = avformat_alloc_context();
        if (!formatContext) {
            std::cerr << "포맷 컨텍스트 할당 실패" << std::endl;
            return false;
        }

        // 파일 열기
        if (avformat_open_input(&formatContext, filename.c_str(), nullptr, nullptr) < 0) {
            std::cerr << "파일 열기 실패: " << filename << std::endl;
            return false;
        }

        // 스트림 정보 찾기
        if (avformat_find_stream_info(formatContext, nullptr) < 0) {
            std::cerr << "스트림 정보 찾기 실패" << std::endl;
            return false;
        }

        // 비디오 스트림 찾기
        for (unsigned int i = 0; i < formatContext->nb_streams; i++) {
            if (formatContext->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                videoStreamIndex = i;
                break;
            }
        }

        if (videoStreamIndex == -1) {
            std::cerr << "비디오 스트림을 찾을 수 없습니다" << std::endl;
            return false;
        }

        // 코덱 찾기
        AVCodecParameters* codecParams = formatContext->streams[videoStreamIndex]->codecpar;
        codec = avcodec_find_decoder(codecParams->codec_id);
        if (!codec) {
            std::cerr << "코덱을 찾을 수 없습니다" << std::endl;
            return false;
        }

        // 코덱 컨텍스트 할당
        codecContext = avcodec_alloc_context3(codec);
        if (!codecContext) {
            std::cerr << "코덱 컨텍스트 할당 실패" << std::endl;
            return false;
        }

        // 코덱 파라미터 복사
        if (avcodec_parameters_to_context(codecContext, codecParams) < 0) {
            std::cerr << "코덱 파라미터 복사 실패" << std::endl;
            return false;
        }

        // 코덱 열기
        if (avcodec_open2(codecContext, codec, nullptr) < 0) {
            std::cerr << "코덱 열기 실패" << std::endl;
            return false;
        }

        // 프레임과 패킷 할당
        frame = av_frame_alloc();
        packet = av_packet_alloc();

        if (!frame || !packet) {
            std::cerr << "프레임/패킷 할당 실패" << std::endl;
            return false;
        }

        printFileInfo();
        return true;
    }

    void printFileInfo() {
        std::cout << "\n=== 파일 정보 ===" << std::endl;
        std::cout << "포맷: " << formatContext->iformat->name << std::endl;
        std::cout << "지속시간: " << formatContext->duration / AV_TIME_BASE << "초" << std::endl;
        
        AVCodecParameters* codecParams = formatContext->streams[videoStreamIndex]->codecpar;
        std::cout << "비디오 코덱: " << avcodec_get_name(codecParams->codec_id) << std::endl;
        std::cout << "해상도: " << codecParams->width << "x" << codecParams->height << std::endl;
        std::cout << "픽셀 포맷 ID: " << codecParams->format << std::endl;
        
        // ProRes 특별 정보
        if (codecParams->codec_id == AV_CODEC_ID_PRORES) {
            std::cout << "🎬 ProRes 파일 감지!" << std::endl;
            std::cout << "비트레이트: " << codecParams->bit_rate / 1000 << " kbps" << std::endl;
        }
    }

    bool decodeFrame() {
        while (av_read_frame(formatContext, packet) >= 0) {
            if (packet->stream_index == videoStreamIndex) {
                int ret = avcodec_send_packet(codecContext, packet);
                if (ret < 0) {
                    std::cerr << "패킷 전송 실패" << std::endl;
                    av_packet_unref(packet);
                    return false;
                }

                ret = avcodec_receive_frame(codecContext, frame);
                if (ret == 0) {
                    std::cout << "프레임 디코딩 성공 - PTS: " << frame->pts << std::endl;
                    av_packet_unref(packet);
                    return true;
                } else if (ret == AVERROR(EAGAIN)) {
                    // 더 많은 패킷이 필요
                    av_packet_unref(packet);
                    continue;
                } else {
                    std::cerr << "프레임 수신 실패" << std::endl;
                    av_packet_unref(packet);
                    return false;
                }
            }
            av_packet_unref(packet);
        }
        return false; // EOF
    }

    void listSupportedFormats() {
        std::cout << "\n=== 지원되는 ProRes 포맷 ===" << std::endl;
        
        const AVCodec* encoder = nullptr;
        void* iter = nullptr;
        
        while ((encoder = av_codec_iterate(&iter))) {
            if (encoder->id == AV_CODEC_ID_PRORES && av_codec_is_encoder(encoder)) {
                std::cout << "인코더: " << encoder->name << " - " << encoder->long_name << std::endl;
            }
        }
        
        iter = nullptr;
        while ((encoder = av_codec_iterate(&iter))) {
            if (encoder->id == AV_CODEC_ID_PRORES && av_codec_is_decoder(encoder)) {
                std::cout << "디코더: " << encoder->name << " - " << encoder->long_name << std::endl;
            }
        }
    }

private:
    void cleanup() {
        if (swsContext) {
            sws_freeContext(swsContext);
            swsContext = nullptr;
        }
        if (frame) {
            av_frame_free(&frame);
        }
        if (packet) {
            av_packet_free(&packet);
        }
        if (codecContext) {
            avcodec_free_context(&codecContext);
        }
        if (formatContext) {
            avformat_close_input(&formatContext);
        }
    }
};

int main(int argc, char* argv[]) {
    std::cout << "🎬 FFmpeg ProRes Player v1.0" << std::endl;
    std::cout << "================================" << std::endl;

    ProResPlayer player;
    
    // 지원되는 포맷 출력
    player.listSupportedFormats();

    if (argc < 2) {
        std::cout << "\n사용법: " << argv[0] << " <비디오파일>" << std::endl;
        std::cout << "예시: " << argv[0] << " sample.mov" << std::endl;
        return 1;
    }

    std::string filename = argv[1];
    
    if (!player.openFile(filename)) {
        std::cerr << "파일 열기 실패: " << filename << std::endl;
        return 1;
    }

    std::cout << "\n=== 프레임 디코딩 시작 ===" << std::endl;
    int frameCount = 0;
    while (player.decodeFrame() && frameCount < 10) { // 처음 10프레임만 테스트
        frameCount++;
    }

    std::cout << "\n총 " << frameCount << "개 프레임 디코딩 완료" << std::endl;
    std::cout << "프로그램 종료" << std::endl;

    return 0;
} 
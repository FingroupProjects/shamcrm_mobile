// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "linphonesw",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "linphonesw",
            targets: ["linphonesw"]
        )
    ],
    targets: [
        
			.binaryTarget(
				name: "bctoolbox-ios",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/bctoolbox-ios.xcframework.zip",
				checksum: "42d61c802348ee12d96139d755b95400a3b69a7e66c8ff25142b2d7c66c0b1c1"
			),
			
			.binaryTarget(
				name: "bctoolbox-tester",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/bctoolbox-tester.xcframework.zip",
				checksum: "a078f385a6dec7e0bf1a231d12b6d2610d644c45f860143387b7631dd52bb75b"
			),
			
			.binaryTarget(
				name: "bctoolbox",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/bctoolbox.xcframework.zip",
				checksum: "68c9d1b54b3852739f5a87d1b208528c0179dca9afe93fae551fe75f4fd2b3d8"
			),
			
			.binaryTarget(
				name: "belcard",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/belcard.xcframework.zip",
				checksum: "8777c14dc1281637fdc8a28d21472c84e9e6f6a6c1349b44d39b285955f8443d"
			),
			
			.binaryTarget(
				name: "belle-sip",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/belle-sip.xcframework.zip",
				checksum: "829038bdc9ffc12640bfaaf99d1a7ceba68c3f793f3227435daaa028c68564df"
			),
			
			.binaryTarget(
				name: "belr",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/belr.xcframework.zip",
				checksum: "a559718a1161de9099df8987c05e97b9715653b1d8abfc5a32f1ed83b96080e4"
			),
			
			.binaryTarget(
				name: "lime",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/lime.xcframework.zip",
				checksum: "ef5ca5b4097146ee2c1a9c0d9fa759d29024e5075975dd15a2f135de2bd54643"
			),
			
			.binaryTarget(
				name: "linphone",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/linphone.xcframework.zip",
				checksum: "c31ed1d282c6e36962fe29969c74ebb7d6fcfad3ffc690e271ee6dee44a01151"
			),
			
			.binaryTarget(
				name: "linphonetester",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/linphonetester.xcframework.zip",
				checksum: "d1d0b120ce67411aee2fe59e3e4f1c0e6d22aafa9eb83d0f053d1ff0789d8843"
			),
			
			.binaryTarget(
				name: "mbedcrypto",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/mbedcrypto.xcframework.zip",
				checksum: "cdcd332ab59f85d59b1b4efec9cb2ec54d4d6235a9712e15046cbfa1149c6b5b"
			),
			
			.binaryTarget(
				name: "mbedtls",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/mbedtls.xcframework.zip",
				checksum: "e326627ed65048a46fa7c3723d51e519c26faf3fa4e91dcc5351a5ea15ff9977"
			),
			
			.binaryTarget(
				name: "mbedx509",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/mbedx509.xcframework.zip",
				checksum: "5d6dec2485e9bf2ed5faf35acbb4bb81ae0935cded1b3e76605ca9260149485f"
			),
			
			.binaryTarget(
				name: "mediastreamer2",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/mediastreamer2.xcframework.zip",
				checksum: "520c60aa3f415da88591fb2781efe8f9a2c4d9b727a916794baba75a17b036e5"
			),
			
			.binaryTarget(
				name: "msamr",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/msamr.xcframework.zip",
				checksum: "4e5735328851e846578ae07f4ff8d3960498d4d13e3ab3084d30e12a1b36dcec"
			),
			
			.binaryTarget(
				name: "mscodec2",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/mscodec2.xcframework.zip",
				checksum: "7b6ff6525f495db365eb966221621fe569c676c162834402850cc2ff1e8c6284"
			),
			
			.binaryTarget(
				name: "msopenh264",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/msopenh264.xcframework.zip",
				checksum: "aaa66e8d46924c77734d6a3cf66fa02cd8fea3e29a64c759550d8062afbe52a5"
			),
			
			.binaryTarget(
				name: "mssilk",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/mssilk.xcframework.zip",
				checksum: "8f9174543ca3956e11a388b6dc8488743e2ed3c8df2ded2908fc35ff483afe3e"
			),
			
			.binaryTarget(
				name: "ortp",
				url: "https://download.linphone.org/releases/ios//spm//linphone-sdk-swift-ios-5.4.106/XCFrameworks/ortp.xcframework.zip",
				checksum: "6e5ea89ff36dd210319a3bbab8465f51fdd86cff45bf1c8920af0302d22594a2"
			),
			
		.target(
			name: "linphonexcframeworks",
			dependencies: ["bctoolbox-ios", "bctoolbox-tester", "bctoolbox", "belcard", "belle-sip", "belr", "lime", "linphone", "linphonetester", "mbedcrypto", "mbedtls", "mbedx509", "mediastreamer2", "msamr", "mscodec2", "msopenh264", "mssilk", "ortp"]
		),

		.target(
			name: "linphonesw",
			dependencies: ["linphonexcframeworks"]
		)
    ]
)


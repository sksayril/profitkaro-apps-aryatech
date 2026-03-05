package com.profitkaro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.tapjoy.Tapjoy
import com.tapjoy.TJConnectListener
import com.tapjoy.TJPlacement
import com.tapjoy.TJPlacementListener
import com.tapjoy.TJActionRequest
import com.tapjoy.TJSetUserIDListener
import java.util.Hashtable

class MainActivity : FlutterActivity() {
    private val CHANNEL = "tapjoy_offerwall"
    private val DEEP_LINK_CHANNEL = "deep_link"
    private var offerwallPlacement: TJPlacement? = null
    private var isContentReady = false

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: android.content.Intent?) {
        if (intent == null) return
        
        val data = intent.data
        if (data != null) {
            val url = data.toString()
            System.out.println("MainActivity: Deep link received: $url")
            
            // Send to Flutter via method channel
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, DEEP_LINK_CHANNEL).invokeMethod(
                    "onDeepLink",
                    mapOf("url" to url)
                )
            }
        }
    }

    override fun onStart() {
        super.onStart()
        val flags = Hashtable<String, Any>()
        Tapjoy.connect(applicationContext, "Z9Y4_msqSmGbgZLCWzsPogECs9zdQNwI88Y6MOAqjPxyCKIJle9HYmysHYoc", flags, object : TJConnectListener() {
            override fun onConnectSuccess() {
                // Set User ID if possible here or wait for Flutter
                
                Tapjoy.setEarnedCurrencyListener { currencyName, amount ->
                    notifyFlutterOfReward(currencyName, amount)
                }
                
                prepareOfferwall()
            }

            override fun onConnectFailure(p0: Int, p1: String?) {}
            override fun onConnectWarning(code: Int, message: String?) {}
        })
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Handle deep links
        handleDeepLink(intent)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showOfferwall" -> {
                    val showed = showOfferwall()
                    result.success(showed)
                }
                "isContentReady" -> {
                    result.success(isContentReady && offerwallPlacement?.isContentReady == true)
                }
                "prepareOfferwall" -> {
                    if (offerwallPlacement == null) {
                        prepareOfferwall()
                    } else {
                        offerwallPlacement?.requestContent()
                    }
                    result.success(true)
                }
                "setUserID" -> {
                    val userId = call.argument<String>("userId")
                    if (userId != null) {
                        Tapjoy.setUserID(userId, object : TJSetUserIDListener {
                            override fun onSetUserIDSuccess() {}
                            override fun onSetUserIDFailure(p0: String?) {}
                        })
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    fun prepareOfferwall() {
        // Placement name from Dashboard: offerwall_main
        System.out.println("Tapjoy: Preparing placement offerwall_main")
        if (offerwallPlacement != null) {
            System.out.println("Tapjoy: Placement already exists, requesting content")
            offerwallPlacement?.requestContent()
            return
        }
        offerwallPlacement = Tapjoy.getPlacement("offerwall_main", object : TJPlacementListener {
            override fun onRequestSuccess(placement: TJPlacement?) {
                System.out.println("Tapjoy: Placement request success")
                // Request content after successful placement request
                placement?.requestContent()
            }
            override fun onRequestFailure(placement: TJPlacement?, error: com.tapjoy.TJError?) {
                System.out.println("Tapjoy: Placement request failure: " + error?.message)
                isContentReady = false
            }
            override fun onContentReady(placement: TJPlacement?) {
                System.out.println("Tapjoy: Content ready for placement - offers available")
                isContentReady = true
            }
            override fun onContentShow(placement: TJPlacement?) {
                System.out.println("Tapjoy: Content show callback")
            }
            override fun onContentDismiss(placement: TJPlacement?) {
                System.out.println("Tapjoy: Content dismissed, reloading...")
                isContentReady = false
                // Reload content for next time
                placement?.requestContent()
            }
            override fun onPurchaseRequest(placement: TJPlacement?, request: TJActionRequest?, productId: String?) {}
            override fun onRewardRequest(placement: TJPlacement?, request: TJActionRequest?, productId: String?, amount: Int) {}
            override fun onClick(placement: TJPlacement?) {}
        })
        offerwallPlacement?.requestContent()
    }

    private fun showOfferwall(): Boolean {
        if (offerwallPlacement == null) {
            System.out.println("Tapjoy: Placement is null, preparing...")
            prepareOfferwall()
            return false
        }
        
        // Check if content is ready - ONLY show if ready
        val contentReady = offerwallPlacement?.isContentReady == true && isContentReady
        
        if (!contentReady) {
            System.out.println("Tapjoy: Content not ready yet. isContentReady=$isContentReady, placement.isContentReady=${offerwallPlacement?.isContentReady}")
            // Request content if not already requested
            if (!isContentReady) {
                System.out.println("Tapjoy: Requesting content...")
                offerwallPlacement?.requestContent()
            }
            return false
        }
        
        // Content is ready, show the offerwall
        return try {
            System.out.println("Tapjoy: Content is ready, showing offerwall...")
            offerwallPlacement?.showContent()
            System.out.println("Tapjoy: Offerwall shown successfully")
            true
        } catch (e: Exception) {
            System.out.println("Tapjoy: Error showing offerwall: ${e.message}")
            e.printStackTrace()
            false
        }
    }

    private fun notifyFlutterOfReward(currencyName: String?, amount: Int) {
        runOnUiThread {
            MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return@runOnUiThread, CHANNEL)
                .invokeMethod("onRewardEarned", mapOf("currency" to currencyName, "amount" to amount))
        }
    }
}
